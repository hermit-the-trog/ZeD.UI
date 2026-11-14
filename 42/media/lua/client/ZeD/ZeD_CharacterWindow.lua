-- ZeD-UI/42/media/lua/client/ZeD/ZeD_CharacterWindow.lua
-- ============================================================================
-- CHARACTER WINDOW — the "me and my stuff" window: inventory, equipment,
-- health, thermal, identity, journal, skills, radio. Client-side; an organism.
-- One plain ZeD_Window, laid out left to right as tab strip | tab drawer |
-- inventory columns | container strip, with the item card drawer over the top.
-- Each tab lives in its own file and registers its renderer here; this file is
-- the shell: layout, drawers, selection, controller focus ring, persistence.
-- The one thing to know: never derive from ISInventoryPage or register with
-- Java's UIManager — that pairing can't be undone from Lua. ZeD builds plain
-- windows and hides the vanilla pages behind them; the game's own
-- "Toggle Inventory" key opens this window and the World window instead.
-- ============================================================================

require "ISUI/ISPanel"
require "ISUI/ISMouseDrag"
require "ISUI/ISUI3DModel"
require "ZeD/WindowCurtain"
require "ZeD/WindowHalves"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/ZeD_TabPx"
require "ZeD/InventoryRenderer"
require "ZeD/ContainerGates"
require "ZeD/ItemCard"
require "ZeD/HealthTab"
require "ZeD/SkillsTab"
require "ZeD/ThermalTab"
require "ZeD/KillTracker"
require "ZeD/JournalTab"
require "ZeD/IdentityTab"
require "ZeD/EquipmentTab"
require "ZeD/TabFind"
require "ZeD/RadioTab"
require "ZeD/ExtraContainers"
require "ZeD/StripDecorators"
require "ZeD/ZeD_WorldWindow"

ZeD = ZeD or {}
ZeD_CharacterWindow = {}

-- Tab content dispatch table — each tab file registers its renderer here.
-- An unregistered tab (only Loot) draws no drawer: lootDrawerFallback folds it.
local TAB_RENDERERS = {}
ZeD_CharacterWindow._tabRenderers = TAB_RENDERERS   -- (QA probes time a tab through it: ZeDUI/tools/qa/zedqa_tab_cost.lua)
ZeD.HealthTab.register(TAB_RENDERERS)
ZeD.SkillsTab.register(TAB_RENDERERS)
ZeD.ThermalTab.register(TAB_RENDERERS)
ZeD.JournalTab.register(TAB_RENDERERS)
ZeD.IdentityTab.register(TAB_RENDERERS)
ZeD.EquipmentTab.register(TAB_RENDERERS)
ZeD.RadioTab.register(TAB_RENDERERS)

-- The open Character windows, one a local player, by player number (0 is the first player). Only the first
-- player's opens for now (ZeD.windowsFor); the map lets split-screen give each player one later.
local _charWins = {}

--- The open Character window, or nil while it is closed. Other files read it
--- (Overrides/RadioWindow.lua refreshes its radio list when a radio is
--- equipped, so the Radio tab shows at once; ZeD_Reader keeps its reading
--- window above it). Same as getWindow(). pn: whose window (nil: the first player's).
function ZeD_CharacterWindow.getInstance(pn)
    return _charWins[pn or 0]
end

-- The shared list renderer (ZeD.InventoryRenderer), fetched on first use so
-- nothing here cares when its file ran.
local R = nil

-- The Loot view has no tab drawer of its own (punch list 156, QA's Mac shoot Nov 11 2026: the Character window's twin
-- of the World window's "Coming soon" card, an English "Tab content - placeholder", showed through the gallery). When
-- Loot is shown with the drawer in tab mode (a restored state, a script, a tab that hid while open), the drawer becomes
-- what is left in it: the item card, the extra columns, or nothing, folded.
local function lootDrawerFallback(win)
    if not win or win._activeTab ~= "loot" or win._drawerMode ~= "tab" then return end
    win._tabUnder = nil
    if win._drawerItem then win._drawerMode = "item"; win._drawerOpen = true
    else
        win._drawerMode = nil
        win._drawerOpen = #(win._mcSelected or {}) > 0
    end
end
ZeD_CharacterWindow._lootDrawerFallback = lootDrawerFallback

local function getR()
    if not R then R = ZeD.InventoryRenderer end
    return R
end

-- The title's name part: the character's first and last name
local function charTitleName(p)
    local d = p and p:getDescriptor()
    if not d then return "" end
    return tostring(d:getForename() or "") .. " " .. tostring(d:getSurname() or "")
end

-- An open item card lies over the tab drawer's right part (from coverX, drawer-
-- local): while the tab draws, every clip it sets is cut at the card's left edge,
-- and clearing one puts that cut back (PZ stencils do not nest). The counts
-- ZeD_Panel keeps of its stencils stay as the tab's own calls make them.
local function coverStencil(p, x, y, w, h)
    local cx = p._coverX or (x + w)
    return ZeD_Panel.setStencilRect(p, x, y, math.max(0, math.min(x + w, cx) - x), h)
end
local function coverClear(p)
    local n = p._zedStencilN
    if n and n > 0 then p._zedStencilN = n - 1 end
    p._coverClears = (p._coverClears or 0) + 1   -- (it sets one again: one more on than the count says)
    ISPanel.clearStencilRect(p)
    return ISPanel.setStencilRect(p, 0, 0, p._coverX or p:getWidth(), p:getHeight())
end
local function setTabCover(p, coverX)
    p._coverX = coverX
    if coverX then p.setStencilRect, p.clearStencilRect = coverStencil, coverClear
    else p.setStencilRect, p.clearStencilRect = nil, nil end
end

-- A Journal entry's "x": the Journal tab asks before the entry goes (its question
-- band, ZeD.JournalTab.askDelete(win, entry, index)). True when it asked; false
-- when the tab has no question to ask (the caller then deletes the entry at once).
local function askJournalDelete(win, idx)
    local JT = ZeD.JournalTab
    if not (JT and JT.askDelete) then return false end
    local md = win and win._playerObj and win._playerObj:getModData()
    local entries = md and md.ZeD_Journal and md.ZeD_Journal.entries
    local entry = entries and entries[idx]
    if entry == nil then return false end
    JT.askDelete(win, entry, idx)
    return true
end

-- ============================================================================
-- TAB STRIP CONSTANTS
-- Every constant below is a DESIGN UNIT (1 px at 1080p). Each use goes
-- through T.px(...) at call time; never add one to screen px unwrapped.
-- ============================================================================

local TAB_STRIP_W  = 36
-- (a tab's cell is row 1's height, ZeD.T.stripH, so the top tab's line runs on the header's: punch list 178)
-- Group separator in the tab strip: off — the tabs already have borders
-- between them, so the line read as noise. Zero height and margin keep
-- layout, hit zones and drawing in step.
local TAB_SEP_H    = 0
local TAB_SEP_MAR  = 0
-- The drawer is one of two widths and no other — a full card and a half card; a third width bumps the
-- cards into each other. ITEM_CARD_W is the half card: the item card is drawn at it, and DRAWER_W (what a
-- tab gets when it asks for less than the full card, and the width a small window steps down to) is the
-- same number. SKILLS_DRAWER_W is the full card.
local ITEM_CARD_W       = 220
local DRAWER_W          = ITEM_CARD_W
local SKILLS_DRAWER_W   = 480
-- The inventory's minimum width beside an open full card: the inventory gives way first. Alone it keeps
-- its 200-unit minimum; beside a full card it may go down to this when half the screen leaves it no more
-- (it scrolls anyway). On the Steam Deck with Large text the full card, the two strips and 200 units of
-- inventory are 9 px over the half-screen cap; with 180 they fit, so the Deck keeps the full card (the
-- doll's bands, the radios' and machines' full faces). Only below this does a tab drop to the half card.
-- ZeD.Scale.FIT_W_UNITS (the UI scale cap) uses the same number.
local INV_MIN_BESIDE_CARD = 180
local DRAWER_SPEED      = 8    -- the slide's pace; only feeds DRAWER_PX_SPEED below
local DRAWER_PX_SPEED   = 260 * DRAWER_SPEED  -- ~2080 design units/sec; scaled at use (T.px(DRAWER_PX_SPEED) * dt)
local CONTAINER_STRIP_W = 36
local CONTAINER_BTN_SZ  = 36
local ARROW_SZ          = 5   -- scroll arrow / chevron size (used in scroll indicators)

-- ============================================================================
-- PERSISTENCE — save/restore window position, size, tab, drawer state
-- ============================================================================

local function charStateOf(win)
    local T  = ZeD.T
    local sc = (T and T.scale) or 1
    -- Save base width (without drawer) so restore opens at inventory-only size.
    -- Persisted geometry is stored in DESIGN UNITS (screen px / T.scale).
    -- _baseInvW already holds design units; positions/heights are screen px and are
    -- divided here. Saves from before UI scaling were written at scale 1.0, so they
    -- read back as-is.
    local liveInvU = win._baseInvW or 372
    -- (a width this screen's fit brought it down to, ZeD.Scale.fitInvW, is saved as the width it came from while the
    -- player has not resized it: a scale round trip opens it at that width again)
    local invU = liveInvU
    if win._fitFromInvW and win._fitInvW and math.abs(T.px(liveInvU) - T.px(win._fitInvW)) <= 1 then invU = win._fitFromInvW end
    local baseW  = TAB_STRIP_W + invU + CONTAINER_STRIP_W   -- design units
    local anchor = ((win._anchorRightEdge or (win:getX() + T.px(TAB_STRIP_W + liveInvU + CONTAINER_STRIP_W))) + (win._rolled and win._rollW or 0)) / sc   -- design units (a rolled side: its unrolled right edge)
    return {
        x = anchor - baseW,
        y = win:getY() / sc,
        w = baseW,
        h = ((win.windowShaded and win.preShadeHeight) or win:getHeight()) / sc,   -- (a rolled-up window: its unrolled height)
        anchorRightEdge = anchor,
        -- (a drawer its half folded opens again on its tab, WindowHalves)
        activeTab  = ZeD.Halves.foldedTab(win) or win._activeTab,
        drawerMode = ZeD.Halves.foldedTab(win) and "tab" or win._drawerMode,
        drawerOpen = ZeD.Halves.foldedTab(win) and true or win._drawerOpen,
        accentKey  = win._accentKey,
    }
end
--- The window's place as the save keeps it (design units, the drawer's tab), for "Save position" (ZeD_WindowPlaces.lua).
ZeD_CharacterWindow.stateOf = charStateOf

local function saveCharState(win)
    local po = win._playerObj
    if not po then return end
    local md = po:getModData()
    md.ZeD_WinState = md.ZeD_WinState or {}
    md.ZeD_WinState.char = charStateOf(win)
end

-- The remembered layout is also written while the window is open, about once
-- a second: the game's OnPostSave runs after the save is already on disk, so a
-- Save and Quit with the window open would otherwise lose every move, resize
-- and tab change made since the window last closed.
local function saveCharStateThrottled(win)
    local now = getTimestampMs()
    if now - (win._lastStateSaveMs or 0) < 1000 then return end
    win._lastStateSaveMs = now
    saveCharState(win)
end

-- The window kept on the current screen: no taller than the screen (less 20 units), no wider,
-- wholly on it, the half-screen width cap measured again. Run after a restore and on a
-- resolution change — a layout saved on a bigger screen, or a screen made smaller, left the
-- window hanging off the bottom; a drag was clamped, these two paths were not. The screen is
-- the one the window lives on (ZeD.screenOf: sl, st its left and top).
local function fitCharToScreen(win)
    if not win then return end
    local T = ZeD.T
    local sw, sh, sl, st = ZeD.screenOf(win)
    win._maxWinW = math.floor(sw * 0.5)
    local w, h = win:getWidth(), win:getHeight()
    local maxH = math.max(win.minimumHeight or T.px(220), sh - T.px(20))
    if h > maxH then h = maxH; win:setHeight(h) end
    if w > sw then w = math.max(win.minimumWidth or 0, sw); win:setWidth(w) end
    local x0 = win:getX()
    local x = math.max(sl, math.min(x0, sl + sw - w))
    local y = math.max(st, math.min(win:getY(), st + sh - h))
    if x ~= x0 then
        -- the right-edge anchor moves with it (a drawer's slide places the window from it)
        win._anchorRightEdge = (win._anchorRightEdge or (x0 + w)) + (x - x0)
        win:setX(x)
        win._lastSetX = x
    end
    if y ~= win:getY() then win:setY(y) end
end
ZeD_CharacterWindow.fitToScreen = fitCharToScreen

local function applyCharState(win, cs)
    local T = ZeD.T
    local screenW, screenH, screenL, screenT = ZeD.screenOf(win)
    -- Stored values are design units (see saveCharState). Scale to screen px,
    -- then clamp to the screen (a saved position can land off-screen after a root change).
    local minW = TAB_STRIP_W + 200 + CONTAINER_STRIP_W           -- design units
    local xU = cs.x or 0
    local yU = math.max(0, cs.y or 60)
    -- no wider than this screen's cap either (half the screen): a layout saved on a bigger
    -- screen would otherwise keep that screen's inventory width
    local capU = math.floor((win._maxWinW or math.floor(screenW * 0.5)) / ((T and T.scale) or 1))
    local wU = math.max(minW, math.min(cs.w or 436, capU))
    local x = T.px(xU)
    local y = T.px(yU)
    local w = T.px(wU)
    local h = math.max(win.minimumHeight or T.px(220), math.min(T.px(cs.h or 600), screenH - T.px(20)))
    if y + h > screenT + screenH then y = math.max(screenT, screenT + screenH - h) end
    -- Right-edge anchor follows x: keep the saved anchor/x relationship, shift both if clamped
    local anchor = T.px(cs.anchorRightEdge or (xU + wU))
    local clampedX = math.max(screenL, math.min(x, screenL + screenW - w))
    anchor = anchor + (clampedX - x)
    x = clampedX
    -- a saved width wider than this screen lets a full card open beside it without shifting: the fitting width, the
    -- right edge kept (ZeD.Scale.fitInvW; the director, Nov 11 2026)
    local fitU = ZeD.Scale and ZeD.Scale.fitInvW and
        ZeD.Scale.fitInvW(T, math.min(win._maxWinW or math.floor(screenW * 0.5), anchor - screenL), TAB_STRIP_W + CONTAINER_STRIP_W)
    win._fitInvW, win._fitFromInvW = nil, nil
    if type(fitU) == "number" and wU - TAB_STRIP_W - CONTAINER_STRIP_W > fitU then
        win._fitFromInvW, win._fitInvW = wU - TAB_STRIP_W - CONTAINER_STRIP_W, fitU
        wU = TAB_STRIP_W + fitU + CONTAINER_STRIP_W
        local w2 = T.px(wU)
        x = math.max(screenL, x + w - w2)
        w = w2
    end
    win:setX(x)
    win:setY(y)
    win:setWidth(w)
    win:setHeight(h)
    win._anchorRightEdge = anchor
    -- Sync inventory drawer to restored width (no stale animation state)
    local restoredInvW = wU - TAB_STRIP_W - CONTAINER_STRIP_W   -- design units
    restoredInvW = math.max(restoredInvW, 200)
    win._invDrawerEffW    = T.px(restoredInvW)
    win._invDrawerTargetW = T.px(restoredInvW)
    win._baseInvW         = restoredInvW                        -- design units
    win._prevDesiredW     = nil  -- let first frame compute fresh
    fitCharToScreen(win)         -- (and the window's own minimums against the screen)
    -- Restore active tab
    if cs.activeTab then
        win._activeTab = cs.activeTab
    end
    -- Restore drawer state (tab drawer reopens where it was)
    if cs.drawerMode == "tab" and cs.drawerOpen and win._activeTab ~= "loot" then
        win._drawerMode = "tab"
        win._drawerOpen = true
    end
    -- Restore per-window accent (modData > Settings pending > default)
    if cs.accentKey then
        win._accentKey = cs.accentKey
    elseif ZeD._pendingCharAccent then
        win._accentKey = ZeD._pendingCharAccent
    end
end
--- A kept place put back on the open window, clamped to this screen ("Go to saved position", ZeD_WindowPlaces.lua).
ZeD_CharacterWindow.applyState = applyCharState

local function restoreCharState(win, playerObj)
    local md = playerObj:getModData()
    local cs = md.ZeD_WinState and md.ZeD_WinState.char
    if cs then applyCharState(win, cs) end
end

-- Per-tab drawer width: every tab listed here asks for the full card (SKILLS_DRAWER_W);
-- a tab not listed gets the half card (DRAWER_W). Item mode is always the half card
-- (ITEM_CARD_W), whichever tab is underneath. A tab another file adds
-- (ZeD_CharacterWindow.addTab) brings its own width, or gets the full card.
local TAB_DRAWER_WIDTHS = {
    equip    = SKILLS_DRAWER_W,
    health   = SKILLS_DRAWER_W,
    skills   = SKILLS_DRAWER_W,
    thermal  = SKILLS_DRAWER_W,
    identity = SKILLS_DRAWER_W,
    journal  = SKILLS_DRAWER_W,
    radio    = SKILLS_DRAWER_W,  -- the radio chassis needs the wider drawer
}

local function getTabDrawerW(tab)
    return TAB_DRAWER_WIDTHS[tab] or DRAWER_W
end

local function getTargetDrawerW(win)
    local T = ZeD.T
    -- Returns SCREEN px (compared against the animated _drawerEffW).
    if win._drawerOpen then
        if win._drawerMode == "item" then return T.px(ITEM_CARD_W) end
        if win._drawerMode == "tab" then
            local want = T.px(getTabDrawerW(win._activeTab))
            local half, full = T.px(DRAWER_W), T.px(SKILLS_DRAWER_W)
            -- The window is capped at half the screen, so on a small screen or a
            -- large text size a full card would squeeze the inventory beside it
            -- below its minimum. The inventory gives way first, down to INV_MIN_BESIDE_CARD
            -- (it scrolls anyway); where even that does not fit with the full card, the
            -- tab gets the half card, never a width in between. Multi-column Loot lifts the
            -- cap, so it is left alone there.
            -- (A rolled side (WindowCurtain) keeps the cap: the drawer stays as wide as it
            -- was, so a roll and an unroll only take the side away and give it back. Lifting
            -- the cap while rolled widened the drawer, shoved the window against the screen
            -- edge and left it elsewhere and at another size after the unroll.)
            local heldIn = false
            if win._invDrawerOpen and #(win._mcSelected or {}) == 0 then
                local maxW = win._maxWinW or math.floor(ZeD.screenOf(win) * 0.5)
                heldIn = maxW - T.px(TAB_STRIP_W) - T.px(CONTAINER_STRIP_W) - T.px(INV_MIN_BESIDE_CARD) < full
            end
            -- a two-way radio: a walkie's tab is the half card wherever one of its widths fits it, else the
            -- full card; a ham set's is the full card, or the card a walkie's width fits with the set's
            -- narrow face where the drawer is held in. Never a width between the two.
            if win._activeTab == "radio" and ZeD.RadioTab and ZeD.RadioTab.wantW then
                local rw = ZeD.RadioTab.wantW(win, want, heldIn and half or full)
                if rw then want = rw end
            end
            if heldIn or want <= half then return half end
            return full
        end
        return 0
    end
    return 0
end

-- ============================================================================
-- MULTI-CONTAINER HELPERS
-- ============================================================================

-- Dynamic MC capacity: max extra columns that fit at MIN_COL_W.
-- MC is only allowed on Loot tab (no tab drawer competing for space).
local function getMcCapacity(win)
    if win._activeTab ~= "loot" then return 0 end  -- MC only on Loot
    local R = getR()
    local T = ZeD.T
    -- InventoryRenderer exports MIN_COL_W / COMFORT_COL_W / getXferW as design units
    local minColW = T.px(R.MIN_COL_W or 140)
    local screenW, _, screenL = ZeD.screenOf(win)
    -- Loot tab has no drawer, so full space is available (to the right edge of the window's screen)
    local availW = screenL + screenW - (win:getX() + T.px(TAB_STRIP_W)) - T.px(CONTAINER_STRIP_W)
    local maxN = 1
    for n = 2, 20 do
        local xferW = T.px(R.getXferW and R.getXferW(n) or 32)
        local needed = n * minColW + (n - 1) * xferW
        if needed > availW then break end
        maxN = n
    end
    return math.max(1, maxN - 1)
end

-- Compute ideal window width for N total columns at comfortable width, clamped to screen.
local function mcComputeTargetWidth(win, totalCols)
    local R = getR()
    local T = ZeD.T
    local comfortW = T.px(R.COMFORT_COL_W or 220)
    local xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
    local xferTotal = (totalCols - 1) * xferW
    local effectiveDrawerW = math.floor(win._drawerEffW or 0)
    local idealInvW = totalCols * comfortW + xferTotal
    local idealWinW = T.px(TAB_STRIP_W) + effectiveDrawerW + idealInvW + T.px(CONTAINER_STRIP_W)
    -- Clamp: can't extend past screen left or right
    local screenW = ZeD.screenOf(win)
    local maxW = screenW - T.px(10)  -- small margin from screen edge
    idealWinW = math.min(idealWinW, maxW)
    return idealWinW, idealInvW
end

-- Compute the target width for the inventory drawer based on current state.
local function computeInvDrawerTarget(win)
    local T = ZeD.T
    if not win._invDrawerOpen then return 0 end
    local mcSel = win._mcSelected or {}
    if #mcSel > 0 then
        local totalCols = #mcSel + (win._mainVisible and 1 or 0)
        if totalCols >= 2 then
            -- Multi-column: compute ideal width
            local _, invW = mcComputeTargetWidth(win, totalCols)
            return invW
        end
        -- Single column (main hidden, 1 MC): keep base width, don't shrink
    end
    return T.px(win._baseInvW or 372)
end

local function getColumnAtX(content, x)
    local colStates = content._colStates
    if not colStates then return nil, nil end
    for i, cs in ipairs(colStates) do
        if x >= cs.renderX and x < cs.renderX + cs.renderW then
            return i, cs
        end
    end
    return nil, nil
end

-- Right-click picks its items the way vanilla's inventory pane does: the row
-- under the cursor becomes the selection unless it is already part of a
-- multi-selection, which is then kept. A stack header or a stack's main row
-- stands for the whole stack. A click on empty space uses the current
-- selection. Returns the menu's items and whether the selection changed.
local function _rmbMenuItems(content, x, y, colIdx, colCs)
    local sel = (colCs and colCs.selectedItems) or content._selectedItems
    local stacksTbl = (colCs and colCs.stacks) or content._stacks
    local zone = content:hitZoneAt(x, y)
    local zid = zone and zone.id
    local rep, clicked
    if type(zid) == "string" then
        if zid:sub(1, 6) == "stack:" then
            -- stacks are keyed by their main item, not by the key string
            local key = zid:sub(7)
            for _, info in pairs(stacksTbl or {}) do
                if info and info.key == key then
                    rep, clicked = info.rep or (info.items and info.items[1]), info.items
                    break
                end
            end
        end
    elseif zid ~= nil then
        rep = zid
        local stk = stacksTbl and stacksTbl[zid]
        if stk and stk.count > 1 and stk.items then clicked = stk.items else clicked = { zid } end
    end

    local menuItems = {}
    if not rep or not clicked then
        for item in pairs(sel) do menuItems[#menuItems + 1] = item end
        return menuItems, false
    end

    local selCount, clickedInSel = 0, false
    for _ in pairs(sel) do selCount = selCount + 1 end
    for _, it in ipairs(clicked) do
        if sel[it] then clickedInSel = true; break end
    end
    if selCount > 1 and clickedInSel then
        for item in pairs(sel) do menuItems[#menuItems + 1] = item end
        return menuItems, false
    end

    -- Select the clicked row (same bookkeeping as a plain left-click)
    for k in pairs(sel) do sel[k] = nil end
    sel[rep] = true
    if colCs then
        colCs.lastClickedItem = rep
        content._selectedItems = sel
        content._activeCol = colIdx
    end
    content._lastClickedItem = rep
    for _, it in ipairs(clicked) do menuItems[#menuItems + 1] = it end
    return menuItems, true
end

local function enterMultiContainer(win, content)
    -- Open drawer for column space. Clear item card if open.
    if win._drawerMode == "item" then
        win._drawerItem = nil
        win._tabUnder = nil
    end
    -- Tab drawers stay open alongside MC columns (loot has no drawer content).
    if win._activeTab and win._activeTab ~= "loot" then
        win._drawerMode = "tab"
    else
        win._drawerMode = nil
    end
    win._drawerOpen = true  -- triggers window growth animation
    win._viewedContainer = nil  -- MC and view are exclusive
    content._selectedItems = {}
    content._lastClickedItem = nil
    -- MC requires visible inventory drawer
    win._invDrawerOpen = true
end

local function exitMultiContainer(win, content)
    local T = ZeD.T
    win._mcSelected = {}
    win._mcColStates = {}
    win._mainVisible = true
    win._activeContainer = 1   -- (main shows, so main is the selection; a pad tap sets its own after)
    content._colStates = nil
    content._selectedContainers = nil
    if win._drawerMode ~= "tab" and win._drawerMode ~= "item" then
        win._drawerOpen = false
    end
    -- Always snap window to base (prevents width corruption from any caller)
    local baseInv = T.px(win._baseInvW or 372)
    local drawerW = math.floor(win._drawerEffW or 0)
    local snapW = T.px(TAB_STRIP_W) + drawerW + baseInv + T.px(CONTAINER_STRIP_W)
    win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
    win:setWidth(snapW)
    local snapX = win._anchorRightEdge - snapW
    win:setX(snapX)
    win._lastSetX = snapX
end

--- The Loot columns closed, back to the one list, as the tab strip closes them on the way to another tab. "Go to
--- saved position" (ZeD_WindowPlaces.lua) starts with it: a place is kept without columns, and one saved on a tab
--- would otherwise open that tab's card beside them.
ZeD_CharacterWindow.closeColumns = function(win)
    if #(win._mcSelected or {}) > 0 and win._mainContent then exitMultiContainer(win, win._mainContent) end
end

-- Forward-decl: mcToggleContainer's tail calls _syncRingZonesToActiveTab to
-- refresh the per-column charMC<n> ring zones. Without hoisting, the closure
-- captures the name as a global at creation time and the
-- `if _syncRingZonesToActiveTab then` guard silently skips.
local _syncRingZonesToActiveTab

local function mcToggleContainer(win, content, cIdx)
    -- MC only allowed on Loot tab
    if win._activeTab ~= "loot" then return end
    local containers = win._containers
    if not containers[cIdx] then return end

    -- Clicking the main (on-person) container: toggle its visibility
    if containers[cIdx].isMain then
        -- (a bag viewed from another tab stays the list on Loot: main does not show then, so a
        -- press shows it, as the World window's floor button does, and opens no other bag as a column)
        local view = win._viewedContainer
        if win._mainVisible and (view == nil or view == 1) then
            if #(win._mcSelected) > 0 then
                -- MC active: only hide main
                win._mainVisible = false
            else
                -- No MC: auto-select first non-main container, then hide main
                local firstOther = nil
                for i, c in ipairs(containers) do
                    if not c.isMain then firstOther = i; break end
                end
                if firstOther then
                    win._mcSelected[1] = firstOther
                    enterMultiContainer(win, content)
                    win._mainVisible = false
                end
                -- else: no other containers, can't hide (nothing to show)
            end
        else
            win._mainVisible = true
            -- (main lit means main is listed: a bag the pad showed does not stay the list under it,
            -- and what was selected there does not stay selected unseen)
            if #win._mcSelected == 0 and (win._viewedContainer or win._activeContainer ~= 1) then
                content._selectedItems = {}
                content._lastClickedItem = nil
            end
            win._viewedContainer = nil
            win._activeContainer = 1
        end
        -- Rebuild columns with updated main visibility (fall through to rebuild below)
        local selected = win._mcSelected
        if #selected == 0 and win._mainVisible then
            -- No MC columns and main visible: single column mode, no rebuild needed
            return
        end
    else
        -- Non-main container: toggle in/out of MC selection
        win._viewedContainer = nil

        local selected = win._mcSelected
        local wasEmpty = #selected == 0

        local idx = nil
        for i, v in ipairs(selected) do
            if v == cIdx then idx = i; break end
        end

        local maxExtra = getMcCapacity(win)
        if idx then
            -- Deselect
            table.remove(selected, idx)
            if #selected == 0 then
                if not win._mainVisible then
                    win._mainVisible = true
                end
                exitMultiContainer(win, content)  -- snaps window internally
                return
            end
        else
            -- Select
            while #selected >= maxExtra do
                table.remove(selected, 1)
            end
            selected[#selected + 1] = cIdx
            if wasEmpty then
                enterMultiContainer(win, content)
            end
        end
    end

    -- Rebuild per-column states
    local selected = win._mcSelected
    local r = getR()
    if r.rebuildColStates then
        local colSel = {}
        for _, ci in ipairs(selected) do
            colSel[#colSel + 1] = ci
        end
        -- Main column = containers[1], never _activeContainer: reading the
        -- active index here duplicated a container into colSel when D-pad
        -- focus had set _activeContainer to the same idx.
        if win._mainVisible then
            colSel[#colSel + 1] = 1
        end

        content._selectedContainers = colSel
        content._containers = containers
        r.rebuildColStates(content)
        content._activeCol = #colSel
    end

    -- Snap window width for new column count
    local T = ZeD.T
    local colCount = #selected + (win._mainVisible and 1 or 0)
    local baseInv = T.px(win._baseInvW or 372)
    if colCount >= 2 then
        -- Multi-column: compute ideal width from column count
        local _, idealInvW = mcComputeTargetWidth(win, colCount)
        local snapW = T.px(TAB_STRIP_W) + idealInvW + T.px(CONTAINER_STRIP_W)
        local maxW = ZeD.screenOf(win) - T.px(10)
        snapW = math.min(snapW, maxW)
        win:setWidth(snapW)
    else
        -- Single column (or main toggle): use base width
        local snapW = T.px(TAB_STRIP_W) + baseInv + T.px(CONTAINER_STRIP_W)
        win:setWidth(snapW)
    end
    local snapX = win._anchorRightEdge - win:getWidth()
    win:setX(snapX)
    win._lastSetX = snapX

    -- MC state changed — rebuild the per-column charMC<n> zones.
    -- _syncRingZonesToActiveTab handles the ring restructuring via its
    -- internal call to _rebuildCharMCRingZones. Without this call, new MC
    -- columns never appear in the ring and bumpers skip them.
    if _syncRingZonesToActiveTab then
        _syncRingZonesToActiveTab(win, content)
    end
end

-- Active scroll dispatch — each scrollable tab has its own scroll state
local function getActiveScroll(win)
    if win._activeTab == "health"  then return win._healthScroll end
    if win._activeTab == "skills"  then return win._skillsScroll end
    if win._activeTab == "thermal" then return win._thermalScroll end
    if win._activeTab == "journal" then
        -- Per-sub-tab scroll dispatch
        local subIdx = win._journalSubTab or 1
        if subIdx == 1 then return win._journalScroll end   -- Journal diary
        if subIdx == 2 or subIdx == 3 then                  -- Notebooks, Papers
            return ZeD.JournalReaders and ZeD.JournalReaders.scroll(win) or nil
        end
        if subIdx == 4 then return nil end    -- Recipes: scroll handled by CraftingCore
        if subIdx == 5 then                   -- Loadouts (ZeD_JournalLists)
            return ZeD.JournalLists and ZeD.JournalLists.scroll(win) or nil
        end
        return win._journalScroll
    end
    if win._activeTab == "identity" then return win._identityScroll end
    if win._activeTab == "equip"    then
        -- the loadouts' to-do scrolls on its own (ZeD_EquipLoadout)
        return (ZeD.EquipLoadout and ZeD.EquipLoadout.scrollFor(win)) or win._equipScroll
    end
    return ZeD_CharacterWindow.extScroll(win)
end

local CHAR_TABS = {
    -- key = ZeD's word for the tab, vkey = vanilla's own where it has the same word;
    -- the tab's name is read where it is shown (ZeD_CharacterWindow.tabLabel), so the language applies.
    { id = "loot",     key = "UI_ZeD_Char_TabLoot",      group = 1, glyph = "L", iconName = "loot-tab-white" },
    { id = "equip",    key = "UI_ZeD_Char_TabEquipment", group = 1, glyph = "E", iconName = "equipment-tab-white" },
    { id = "health",   vkey = "IGUI_XP_Health",          group = 1, glyph = "H", iconName = "health-tab-white" },
    { id = "thermal",  key = "UI_ZeD_Char_TabThermal",   group = 1, glyph = "T", iconName = "thermal-tab-white" },
    { id = "identity", key = "UI_ZeD_Char_TabIdentity",  group = 2, glyph = "I", iconName = "identy-tab-white" },
    { id = "journal",  key = "UI_ZeD_Char_TabJournal",   group = 2, glyph = "J", iconName = "journal-tab-white" },
    { id = "skills",   vkey = "IGUI_XP_Skills",          group = 2, glyph = "S", iconName = "skills-tab-white" },
    -- Radio is contextual: visible only while the player carries an equipped
    -- or portable radio. Mirrors the World window's contextual-tab predicate.
    { id = "radio",    key = "UI_ZeD_Char_TabRadio",     group = 2, glyph = "R",
      iconName = "radio-tab-white",
      visible = function(win)
          return win and win._radios and #win._radios > 0
      end },
}

--- A tab's name in the player's language (the D-pad wheels read it too).
function ZeD_CharacterWindow.tabLabel(tab)
    if tab.label then return tab.label() end
    if tab.vkey then return getText(tab.vkey) end
    return ZeD.tr(tab.key)
end

-- The title: the character's name, then what the window shows: the open tab ("Angel
-- Cross  +  Health"), else the bag being viewed ("Angel Cross  +  Fanny Pack") or the
-- columns (win._titleSub, set by the inventory side). Two parts at most, so it never
-- reads as a path. Built every frame from the window's own prerender — built in the
-- inventory side's prerender it went stale, since that side does not draw while the
-- tab drawer takes the whole window (1280x720 at UI scale 2.0, Large text), and the
-- title kept whatever tab was open when the side last showed. The words are kept
-- until a part changes (no new string a frame).
local function composeCharTitle(win)
    local p = win._playerObj
    if win._ttP ~= p then win._ttP, win._ttName = p, charTitleName(p) end
    local sub = win._titleSub
    -- (a tab drawer rolled in by its half keeps its tab in the title, WindowHalves)
    local tabId = (win._drawerOpen and win._drawerMode == "tab" and win._activeTab) or ZeD.Halves.foldedTab(win)
    if tabId then
        for _, tab in ipairs(CHAR_TABS) do
            if tab.id == tabId then
                sub = ZeD_CharacterWindow.tabLabel(tab)
                break
            end
        end
    end
    if win._ttOut == nil or sub ~= win._ttSub or win._ttName ~= win._ttOutName then
        win._ttSub, win._ttOutName = sub, win._ttName
        win._ttOut = (sub and sub ~= "") and (win._ttName .. "  +  " .. sub) or win._ttName
    end
    win.title = win._ttOut
end

-- The health status pixel before the name (the director, Nov 11 2026: it took the place of "100%" in the stats, so
-- the name stays in the bar while pins show). Its color and blink are ZeD_Window.healthPixel's bands; resting the
-- pointer on it or the name puts "Health: 63%" in the help line, the words kept until the whole percent changes.
-- The name gives way to the stats (_titleYields): pins shorten, then the name is cut with "...", then pins drop.
local function composeCharHealth(win)
    local p = win._playerObj
    local bd = p and p:getBodyDamage()
    if not bd then win._titleMark, win._titleHelp = nil, nil; return end
    -- (cut down, as the Health tab's Overall row: 99.6 is "Health: 99%", never 100% while the game says Slight damage)
    local hp = math.floor(bd:getOverallBodyHealth())
    win._titleMark, win._titleMarkBlink = ZeD_Window.healthPixel(hp)
    win._titleYields = true
    win._hideTitle = nil
    if win._hpHelpV ~= hp then
        win._hpHelpV = hp
        win._hpHelpS = ZeD.tr("UI_ZeD_Char_HealthHelp", getText("IGUI_XP_Health"), ZeD.Atoms.pctText(hp / 100))
    end
    win._titleHelp = win._hpHelpS
end

--- A tab that another file adds: ZeD's own extras (CookingTab, ServerTab) and
--- ZeD's support for other mods (ZeD/ModSupport/<mod id>.lua, loaded only when
--- that mod is on). def: id, label(), group, iconName, after (a tab id),
--- visible(win), render(panel, win, x, y, w, h) as the other tabs, and
--- optionally scroll(win) (its ZeD_ScrollbarState), onClick(win, x, y),
--- buildFocusables(win), onWindowFrame(win, drawerW) (every frame, any tab:
--- place or hide window-parented children such as 3D figures).
ZeD_CharacterWindow._extTabs = {}
function ZeD_CharacterWindow.addTab(def)
    if ZeD_CharacterWindow._extTabs[def.id] then return end
    ZeD_CharacterWindow._extTabs[def.id] = def
    TAB_RENDERERS[def.id] = def.render
    TAB_DRAWER_WIDTHS[def.id] = def.drawerW or SKILLS_DRAWER_W
    local at = #CHAR_TABS + 1
    for i, t in ipairs(CHAR_TABS) do
        if t.id == def.after then at = i + 1 end
    end
    table.insert(CHAR_TABS, at, def)
end
-- The added tabs' dispatchers live on the module, not as locals: they are
-- called from the window's own functions, which are near Kahlua's limit of locals.
function ZeD_CharacterWindow.extScroll(win)
    local ext = ZeD_CharacterWindow._extTabs[win._activeTab]
    return ext and ext.scroll and ext.scroll(win) or nil
end
function ZeD_CharacterWindow.extFocusables(win, tabId)
    local ext = ZeD_CharacterWindow._extTabs[tabId]
    return ext and ext.buildFocusables and ext.buildFocusables(win) or {}
end
function ZeD_CharacterWindow.extClick(win, x, y)
    local ext = ZeD_CharacterWindow._extTabs[win._activeTab]
    if not (ext and ext.onClick) then return false end
    ext.onClick(win, x, y)
    return true
end
function ZeD_CharacterWindow.extScrollKey(win)
    local ext = ZeD_CharacterWindow._extTabs[win._activeTab]
    return ext and ext.scrollKey and ext.scrollKey(win) or nil
end
function ZeD_CharacterWindow.extFrame(win, drawerW)
    -- the Identity tab's hair and beard figures: off until the section draws them this frame
    if ZeD.HairBeard and ZeD.HairBeard.onWindowFrame then
        local ok, err = pcall(ZeD.HairBeard.onWindowFrame, win, drawerW)
        if not ok then ZeD.logOnce("hairbeard frame", err) end
    end
    -- the Skills and Equipment tabs' Find fields: shown only while their heading draws them
    if ZeD.TabFind then
        local ok, err = pcall(ZeD.TabFind.onWindowFrame, win, drawerW)
        if not ok then ZeD.logOnce("tab find frame", err) end
    end
    for _, ext in pairs(ZeD_CharacterWindow._extTabs) do
        if ext.onWindowFrame then
            local ok, err = pcall(ext.onWindowFrame, win, drawerW)
            if not ok then ZeD.logOnce("tab frame " .. tostring(ext.id), err) end
        end
    end
end

-- Contextual-tab visibility dispatch — mirror of ZeD_WorldWindow's
-- isTabVisible. A nil tab.visible means "always show"; a tab that comes and
-- goes (radio) opts in by declaring a predicate.
local function isTabVisible(tab, win)
    if not tab.visible then return true end
    return tab.visible(win)
end
--- The tabs and their visibility test, for the D-pad wheels' Tabs slice (ZeD_DpadWheels.lua).
ZeD_CharacterWindow.TABS = CHAR_TABS
ZeD_CharacterWindow.isTabVisible = isTabVisible

-- ============================================================================
-- GAMEPAD FOCUS SUPPORT
-- Builds focusable-element lists ("stops") for FocusManager's cone spatial
-- nav and switches tabs when D-pad cycling lands on a new one. Coordinates
-- are in tab-strip-local space for tabBar elements (FocusManager cone nav
-- uses relative distances, so any consistent frame is fine per frame).
-- ============================================================================

-- Build the tabBar focusable list — one element per CHAR_TABS entry, bounds
-- computed from the same constants drawTabStrip uses so positions stay in sync
-- if strip layout constants shift. Returns plain data; the caller attaches the
-- onFocus/onActivate callbacks (_attachTabBarCallbacks: they need
-- _switchTabForNav and the window's content panel).
local function _buildTabBarElements(win)
    local T = ZeD.T
    local elements = {}
    local curY = 0
    local lastGroup = 1
    for i, tab in ipairs(CHAR_TABS) do
        if not isTabVisible(tab, win) then
            -- Skip hidden contextual tabs (radio with no radio carried).
            -- Group separator still suppressed; if the next visible tab is in a
            -- different group the separator fires on its own iteration.
        else
            if tab.group ~= lastGroup then
                -- Mirror drawTabStrip's group-separator spacing (mar + sep + mar)
                curY = curY + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            elements[#elements + 1] = {
                x = 0, y = curY, w = T.px(TAB_STRIP_W), h = T.stripH,   -- (the strip's width; only the height is row 1)
                id       = "tab:" .. tab.id,
                tabId    = tab.id,
                tabIndex = i,
            }
            curY = curY + T.stripH
        end
    end
    return elements
end

-- Forward-declarations for helpers _syncRingZonesToActiveTab references.
-- Each helper is defined later in the file (after the per-tab focusable
-- builders, where the locals it depends on ARE in scope). Declaring them
-- here as `local X` and assigning later via `X = function...` (instead of
-- `local function X(...)`) makes them visible to the closure built by
-- _syncRingZonesToActiveTab.
local _buildPanelFocusables
local _buildLootFocusables
local _clearGpFocusState
-- The MC column builder is forward-declared HERE, before the
-- _syncRingZonesToActiveTab forward-decl above is assigned, so the sync
-- closure captures the local correctly. A Kahlua trap: closures resolve the
-- enclosing scope at CALL TIME but only see names that existed as locals at
-- CLOSURE-CREATION time. A forward-decl written after the closure becomes a
-- global lookup inside it — nil here, since the real definition is also
-- local. Hoist every forward-decl above all its consumers.
local _buildCharacterMCColumnFocusables
-- Forward-declared so _syncRingZonesToActiveTab and the per-frame
-- refresh block can reference it (defined after _buildInvRowFocusables).
local _buildCardActionFocusables
-- Forward-declared so the skill row stops (_buildSkillRowFocusables) can
-- capture skillRowMenu as an upvalue; both are assigned under PINNED SKILLS,
-- much later in the file.
local togglePinSkill
local skillRowMenu   -- (the skill row's menu, assigned with togglePinSkill below)

-- The ring zones synced to the new active tab (the function two blocks down).
-- Called from _switchTabForNav on both the loot-snap and non-loot-drawer
-- paths, so the two branches share one set of mutations and don't drift.
-- Reads the new _activeTab off win.
-- This first helper restructures the per-column MC zones, mirroring the World
-- window: each MC selection becomes its own ring zone (charMC1..charMCN),
-- inserted just before charMainInv (the order is explained below).
local function _rebuildCharMCRingZones(win)
    local ring = win and win._focusRing
    if not ring then return end
    -- the new zones start from this build: the per-frame refresh rebuilds them next frame
    win._lastMCSnap = nil

    local focusedName = nil
    if win._focusIdx and ring[win._focusIdx] then
        focusedName = ring[win._focusIdx].zone
    end

    -- Remove existing charMC<n> zones (in reverse to preserve indices).
    for i = #ring, 1, -1 do
        local z = ring[i]
        if z and z.zone and z.zone:match("^charMC%d+$") then
            table.remove(ring, i)
        end
    end

    -- MC zones go in BEFORE charMainInv so ring order matches the visual L→R
    -- layout: the content panel renders MC cols at colStates[1..K] (leftmost)
    -- with main = colStates[N] = rightmost. Inserted before charItemCard
    -- instead, mainInv came BEFORE the MC zones in the ring and the bumpers
    -- moved against the eye. Order: tabBar → tabContent → charMC1
    -- → ... → charMCN → charMainInv → charItemCard → charContainerStrip.
    local insertAt = nil
    for i, z in ipairs(ring) do
        if z and z.zone == "charMainInv" then insertAt = i; break end
    end

    local mcSel = win._mcSelected or {}
    if insertAt and win._activeTab == "loot" and #mcSel > 0 then
        for slot = 1, #mcSel do
            local zoneName = "charMC" .. slot
            local mcEls = _buildCharacterMCColumnFocusables(win, slot) or {}
            local capturedSlot = slot
            local newZone = {
                zone = zoneName,
                focusable = #mcEls > 0,
                elements = mcEls,
                focusedElementIdx = 1,
                uiRange = function(w)
                    -- cs.renderX is content-panel-relative; the content
                    -- starts at TAB_STRIP_W + drawerEffW (left tab strip +
                    -- drawer), so offset by that to get window-absolute x
                    -- for the focus underline.
                    local T = ZeD.T
                    local content = w._mainContent
                    if content and content._colStates and content._colStates[capturedSlot] then
                        local cs = content._colStates[capturedSlot]
                        if cs.renderX and cs.renderW then
                            local dw = math.floor(w._drawerEffW or 0)
                            return T.px(TAB_STRIP_W) + dw + cs.renderX, cs.renderW
                        end
                    end
                    return T.px(TAB_STRIP_W) + math.floor(w._drawerEffW or 0), T.px(200)
                end,
            }
            table.insert(ring, insertAt, newZone)
            insertAt = insertAt + 1
        end
    end

    if focusedName then
        local found = nil
        for i, z in ipairs(ring) do
            if z.zone == focusedName then found = i; break end
        end
        if found then
            win._focusIdx = found
        elseif focusedName:match("^charMC%d+$") then
            for i, z in ipairs(ring) do
                if z.zone == "charMainInv" and z.focusable then
                    win._focusIdx = i; break
                end
            end
        end
    end
end

_syncRingZonesToActiveTab = function(win, content)
    if not (ZeD and ZeD.Input and ZeD.Input.Focus and win and win._focusRing) then return end
    local Focus  = ZeD.Input.Focus
    local tabId  = win._activeTab

    -- Capture the currently focused containerIdx BEFORE the rebuild.
    -- Container onFocus is a no-op, so _activeContainer doesn't track
    -- D-pad nav; seeding from it made focus jump after an MC toggle.
    -- Prefer the live focused container, fall back to active.
    local focusedCidx = nil
    do
        local zoneNow = Focus.getFocusedZone and Focus.getFocusedZone(win)
        if zoneNow and zoneNow.zone == "charContainerStrip" then
            local elNow = Focus.getFocusedElement and Focus.getFocusedElement(win)
            if elNow then focusedCidx = elNow.containerIdx end
        end
    end

    local newContentEls   = _buildPanelFocusables(win, content, tabId) or {}
    -- Containers are reachable on ALL tabs. The MC toggle (an A press) is
    -- Loot-only — enforced inside container onActivate.
    local newContainerEls = _buildLootFocusables(win) or {}

    Focus.setRingZoneElements(win, "charTabContent",     newContentEls, 1)
    Focus.setZoneFocusable   (win, "charTabContent",     #newContentEls > 0)
    -- Seed the containerStrip index by scanning for the element whose
    -- containerIdx matches the captured focus (or the _activeContainer fallback).
    local seedTarget = focusedCidx or win._activeContainer
    local contIdx = 1
    if seedTarget and #newContainerEls > 0 then
        for i, el in ipairs(newContainerEls) do
            if el.containerIdx == seedTarget then
                contIdx = i; break
            end
        end
    end
    Focus.setRingZoneElements(win, "charContainerStrip", newContainerEls, contIdx)
    Focus.setZoneFocusable   (win, "charContainerStrip", #newContainerEls > 0)

    -- Rebuild the per-column MC zones from the _mcSelected count.
    _rebuildCharMCRingZones(win)

    -- Tab changes always leave "item" mode (_switchTabForNav flips
    -- _drawerMode to "tab" or nil). Explicitly disable the card zone now so a
    -- bumper press in the same frame can't land on stale card elements before
    -- the per-frame refresh catches up next frame.
    Focus.setRingZoneElements(win, "charItemCard", {})
    Focus.setZoneFocusable   (win, "charItemCard", false)

    _clearGpFocusState(win)
    if win._rolled and win._curtain and win._curtain.onFrame then win._curtain.onFrame() end
end

-- Switch active tab from a gamepad-nav context. Mirrors the "different tab"
-- branch of the tab strip's mouse click handler (strip.onMouseDown, far
-- below), with the loot-tab special case folded in. Kept as a separate helper
-- rather than refactoring the click handler because duplication here is
-- cheaper than risking the click path. Returns true if the tab actually
-- changed, false otherwise. After tab state is fully mutated on either
-- branch, calls _syncRingZonesToActiveTab so the ring reflects the new tab.
local function _switchTabForNav(win, content, tabId)
    if not win or not content or not tabId then return false end
    if win._activeTab == tabId then
        -- (a drawer folded by the pointer keeps its tab selected: A on that tab brings it back)
        if ZeD.Halves and ZeD.Halves.foldedTab and ZeD.Halves.foldedTab(win) == tabId then ZeD.Halves.showAll(win); return true end
        return false
    end
    local T = ZeD.T

    local mcSel = win._mcSelected or {}
    local mcActive = #mcSel > 0

    if tabId == "loot" then
        -- Loot is the "drawer-closed" special state: snap back to inventory-only
        -- (a rolled side comes down first: the snap measures the whole window)
        if win._rolled then ZeD.Curtain.finishUnroll(win) end
        win._activeTab  = "loot"
        win._drawerItem = nil
        win._drawerMode = nil
        win._drawerOpen = false
        win._tabUnder   = nil
        content._selectedItems = {}
        content._lastClickedItem = nil
        local baseInv = T.px(win._baseInvW or 372)
        win._drawerEffW    = 0
        win._prevEffW      = 0
        win._invDrawerOpen = true
        local snapW = T.px(TAB_STRIP_W) + baseInv + T.px(CONTAINER_STRIP_W)
        win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
        win:setWidth(snapW)
        local snapX = win._anchorRightEdge - snapW
        win:setX(snapX)
        win._lastSetX = snapX
        _syncRingZonesToActiveTab(win, content)
        return true
    end

    -- Non-loot tab: open drawer + switch content, with MC exit + base snap
    if mcActive then
        exitMultiContainer(win, content)
        local baseInv = T.px(win._baseInvW or 372)
        local snapW = T.px(TAB_STRIP_W) + baseInv + T.px(CONTAINER_STRIP_W)
        win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
        win:setWidth(snapW)
        local snapX = win._anchorRightEdge - snapW
        win:setX(snapX)
        win._lastSetX = snapX
    end
    if not win._drawerOpen then
        win._preDrawerW = win:getWidth()
    end
    win._activeTab  = tabId
    win._drawerMode = "tab"
    win._drawerOpen = true
    win._drawerItem = nil
    win._tabUnder   = nil
    -- Reset tab-scoped scroll + caches so the new tab renders fresh
    local scroll = getActiveScroll(win)
    if scroll then scroll:setScrollPos(0) end
    win._healthCache    = nil
    win._skillsCache    = nil
    win._trainingCache  = nil
    win._equipProtCache = nil
    win._thermalCache   = nil
    win._identityCache  = nil
    win._identityPhotoRect = nil
    win._equipCache    = nil
    win._equipSelected = nil
    content._selectedItems = {}
    content._lastClickedItem = nil
    _syncRingZonesToActiveTab(win, content)
    return true
end

-- Forward-declare _buildInvRowFocusables so _buildLootFocusables'
-- onConfirm closure can reference it (the Kahlua trap again: locals
-- declared after a function aren't visible inside its closures).
local _buildInvRowFocusables
-- The MC column builder's forward-decl is hoisted to the block above
-- _syncRingZonesToActiveTab (see the note there); this marker stays so
-- nobody re-declares it here, below that closure.

-- The container strip's stops. The strip lives on the RIGHT edge of the
-- window (CONTAINER_STRIP_W wide), one cell per entry in `win._containers`
-- (dynamic — it grows when the player equips a bag). Coordinates are
-- panel-local; focusing a container only moves the mark, and A commits
-- (see the element callbacks below).
--
-- First, the pad's drag-reorder, mirroring the mouse drag-and-drop
-- completion path: mutate _containerOrder, clear the sort-by-weight flag,
-- then rebuild the charContainerStrip stops so the moved container's
-- y-bounds update on the next render. Matching by containerIdx keeps the
-- focus locked on the dragged container.
local function _gpReorderCharContainer(win, containerIdx, dir)
    if not win or not containerIdx then return end
    local order = win._containerOrder
    if not order or #order == 0 then return end
    local srcIdx
    for oi, ci in ipairs(order) do
        if ci == containerIdx then srcIdx = oi; break end
    end
    if not srcIdx then return end
    local target
    if dir == "up" and srcIdx > 1 then
        target = srcIdx - 1
    elseif dir == "down" and srcIdx < #order then
        target = srcIdx + 1
    end
    if not target then return end
    local val = table.remove(order, srcIdx)
    table.insert(order, target, val)
    win._containerSortByWT  = false
    win._containerSortMode  = "dist"  -- forced sort mode would override the manual order
    -- Rebuild charContainerStrip focusables so the dragged container's y
    -- coord reflects its new slot. Identity-preserve by containerIdx.
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if Focus and Focus.setRingZoneElements then
        local newEls = _buildLootFocusables(win) or {}
        local newIdx = 1
        for i, el in ipairs(newEls) do
            if el.containerIdx == containerIdx then newIdx = i; break end
        end
        Focus.setRingZoneElements(win, "charContainerStrip", newEls, newIdx)
    end
end

-- A on a container goes on to its first item once its rows have drawn
-- (World window parity); an empty one keeps the focus on the button.
local function _focusFirstRowSoon(w, inv)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if not (inv and Fo and Fo.focusSoon) then return end
    Fo.focusSoon(w, "charMainInv", function(e) return e.item ~= nil and e.item:getContainer() == inv end, 1)
end

_buildLootFocusables = function(win)
    if not win or not win._containers then return {} end
    local n = #win._containers
    if n == 0 then return {} end
    local T = ZeD.T
    -- Panel-local coordinates: the focus manager adds the strip panel's
    -- offset itself (window-local put every stop a strip-width right and a
    -- body-height low), from the places the strip drew last (win._stripLay)
    local stripX = 0
    local stripY = 0
    -- Match the visual layout of drawContainerStrip exactly. Zone 1
    -- (main) at y=stripY, row 1 (T.stripH, its line included). Zone 2 (sort row)
    -- under it, row 2 (T.sortBarH). Zone 3 (non-main buttons) starts under
    -- both. A uniform (i-1)*W here made the stops' y-coords
    -- mismatch the drawn buttons after containers were reordered by sort or
    -- by hand.
    local L = win._stripLay
    local zone3Y = (L and L.listY) or (stripY + T.stripH + T.sortBarH)
    zone3Y = zone3Y - ((L and L.scroll) or 0)

    local elements = {}
    -- Element 1: main (always pinned at Zone 1 top).
    -- onFocus never mutates _activeContainer. When the focus callback wrote
    -- the focused index there, it cascaded into (a) a duplicate column when
    -- adding a non-main bag to MC, because colSel appended _activeContainer
    -- as the "main column" — the same idx landed at positions 1 and N; and
    -- (b) a stale view-preview after MC exit. _activeContainer stays pinned
    -- at 1 (main) for the whole Loot flow; MC column layout is derived purely
    -- from _mcSelected + _mainVisible.
    local mainCnt = win._containers[1]
    if mainCnt then
        elements[#elements + 1] = {
            x = stripX, y = stripY, w = T.px(CONTAINER_STRIP_W), h = T.stripH - T.px(1),
            id = "container:1",
            containerIdx = 1,
            inventory = mainCnt.inventory,
            onFocus = function(w, el) end,
            -- Tap = switch active container (no tab swap, no MC). On Loot,
            -- exits MC if active and shows this container as the
            -- single-column view. On non-Loot, only sets active — the player
            -- can swap to Loot later to see the items. Hold is the cross-tab
            -- MC toggle (snaps to Loot first, then toggles the column).
            -- _mainVisible mirrors "is main the displayed container?" — only
            -- true when the picked container IS main, else false (the main
            -- button must not paint its accent fill while a different
            -- container is viewed via the _viewedContainer override).
            onActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                if w._activeTab == "loot"
                   and w._mcSelected and #w._mcSelected > 0 then
                    exitMultiContainer(w, c)
                end
                w._activeContainer = el.containerIdx
                w._viewedContainer = el.containerIdx
                w._mainVisible     = (el.containerIdx == 1)
                _focusFirstRowSoon(w, el.inventory)
            end,
            onHoldActivate = function(w, el)
                local c = w._mainContent
                if not c then return end
                if w._activeTab ~= "loot" then
                    _switchTabForNav(w, c, "loot")
                end
                if mcToggleContainer then
                    mcToggleContainer(w, c, el.containerIdx)
                end
            end,
        }
    end

    -- Elements 2..N: non-main containers in display order. Match
    -- drawContainerStrip's listEntries loop so focusable y-coords track
    -- whatever sort/drag-reorder the user applied.
    local order = win._containerOrder
    if not order or #order ~= n then
        order = {}
        for i = 1, n do order[i] = i end
    end
    local sortMode = win._containerSortMode or "dist"
    if L and L.entries then
        order = L.entries   -- (the order the strip drew, main left out)
    elseif sortMode == "wt" or sortMode == "type" then
        -- Use a shallow copy for the visual sort so we don't mutate the
        -- stored order (drawContainerStrip mutates a shared array too, but
        -- the builder shouldn't fight with it).
        local snap = {}
        for i = 1, #order do snap[i] = order[i] end
        local containers = win._containers
        if sortMode == "wt" then
            table.sort(snap, function(a, b)
                if containers[a].isMain then return true end
                if containers[b].isMain then return false end
                local wa = containers[a].inventory and containers[a].inventory:getCapacityWeight() or 0
                local wb = containers[b].inventory and containers[b].inventory:getCapacityWeight() or 0
                return wa > wb
            end)
        else
            table.sort(snap, function(a, b)
                if containers[a].isMain then return true end
                if containers[b].isMain then return false end
                return (containers[a].name or "") < (containers[b].name or "")
            end)
        end
        order = snap
    end

    local displayPos = 0
    for _, ci in ipairs(order) do
        if ci ~= 1 and win._containers[ci] then
            displayPos = displayPos + 1
            local cy = zone3Y + (displayPos - 1) * T.px(CONTAINER_BTN_SZ)
            elements[#elements + 1] = {
                x = stripX, y = cy, w = T.px(CONTAINER_STRIP_W), h = T.px(CONTAINER_BTN_SZ),
                id = "container:" .. tostring(ci),
                containerIdx = ci,
                inventory = win._containers[ci].inventory,
                onFocus = function(w, el) end,
                -- Same tap-vs-hold model as the main container.
                -- Tap = switch active (no tab swap). Hold = MC toggle, with
                -- the cross-tab snap to Loot baked in. _mainVisible mirrors
                -- "is main the displayed container?" — false here since this
                -- closure is for non-main (idx != 1).
                onActivate = function(w, el)
                    local c = w._mainContent
                    if not c then return end
                    if w._activeTab == "loot"
                       and w._mcSelected and #w._mcSelected > 0 then
                        exitMultiContainer(w, c)
                    end
                    w._activeContainer = el.containerIdx
                    w._viewedContainer = el.containerIdx
                    w._mainVisible     = false
                    _focusFirstRowSoon(w, el.inventory)
                end,
                onHoldActivate = function(w, el)
                    local c = w._mainContent
                    if not c then return end
                    if w._activeTab ~= "loot" then
                        _switchTabForNav(w, c, "loot")
                    end
                    if mcToggleContainer then
                        mcToggleContainer(w, c, el.containerIdx)
                    end
                end,
                -- HOLD X + D-pad UP/DOWN = drag-reorder this container
                -- in the strip (mouse-drag parity). Each D-pad press while X
                -- is held swaps the container with its neighbor in
                -- _containerOrder; release X to commit (no rollback). Only
                -- non-main containers (ci != 1) are reorderable, mirroring
                -- the mouse drag's `isMain` guard. dir == nil signals drag-
                -- mode entry — no-op (could play a sound / paint cue later).
                onHoldContextDrag = function(w, el, dir)
                    if dir == nil then return end
                    _gpReorderCharContainer(w, el.containerIdx, dir)
                end,
                onHoldContextRelease = function(w, el)
                    -- Commit is implicit (order already updated). No rollback.
                end,
            }
        end
    end
    return elements
end

-- The strip's stops, rebuilt whenever the bag list, its order or its scroll
-- changes (built only at open and on a tab switch, a bag put on afterwards
-- would have no stop); the focus stays on the same bag (by inventory).
local function _refreshCharStripFocus(win, Focus)
    local L = win._stripLay
    local cnts = win._containers
    if not (L and cnts and win._focusRing) then return end
    local sum = 0
    for i, ci in ipairs(L.entries or {}) do sum = sum + i * ci end
    local sig = win._stripFocusSig
    if sig and sig.cnts == cnts and sig.scroll == L.scroll and sig.listY == L.listY
       and sig.sum == sum and sig.n == #cnts then return end
    win._stripFocusSig = { cnts = cnts, scroll = L.scroll, listY = L.listY, sum = sum, n = #cnts }
    local zone
    for _, z in ipairs(win._focusRing) do if z.zone == "charContainerStrip" then zone = z; break end end
    if not zone then return end
    local old = zone.elements and zone.elements[zone.focusedElementIdx or 1]
    local oldInv = old and old.inventory
    local els = _buildLootFocusables(win) or {}
    local keep = 1
    local want = win._viewedContainer or win._activeContainer
    for i, e in ipairs(els) do
        if (oldInv and e.inventory == oldInv) or (not oldInv and e.containerIdx == want) then keep = i; break end
    end
    Focus.setRingZoneElements(win, "charContainerStrip", els, keep)
    Focus.setZoneFocusable(win, "charContainerStrip", #els > 0)
end

-- The strip's landing (FocusManager zone.landOn): the bag on show.
local function _charStripLandOn(w, z)
    local want = w._viewedContainer or w._activeContainer
    for i, e in ipairs(z.elements or {}) do
        if e.containerIdx == want then return i end
    end
    return nil
end

-- The list's landing from the side: the row focus last had, while it is a row
-- in view (else the spatial pick).
local function _charInvListLandOn(w, z, dir)
    if dir == "up" or dir == "down" then return nil end
    local e = z.elements and z.elements[z.focusedElementIdx or 1]
    local c = w._mainContent
    if not (e and e.item and c) then return nil end
    if e.y < 0 or e.y + e.h > c:getHeight() then return nil end
    return z.focusedElementIdx or 1
end

-- The Skills tab's stops, built from the win._skillRowZones table that
-- SkillsTab.lua populates each frame. Snapshot the zones; if layout shifts
-- on a later frame, a re-push will refresh.
--
-- Three builders + an aggregator, mirroring the Thermal structure.
-- Disclosure FIRST (the tree-nav rule every tab follows). Skill rows guard
-- on _skillsGridExpanded because they only render when the grid is open;
-- training chevrons do NOT guard because the training section always renders
-- (a collapsed grid still shows training). The paint cue stays
-- live-element-gated in SkillsTab.render, so the state field is written for
-- scroll-follow keying only, not paint.

-- Skills disclosure — element[1] in charTabContent. Reuses _skillsGridZone
-- which is stamped at the END of SkillsTab.render after drawTabHeader (so
-- the rect is one-frame-lagged — same pattern as _thermalFigureZone).
local function _buildSkillsDisclosureFocusable(win)
    local fz = win and win._skillsGridZone
    if not fz or (fz.w or 0) <= 0 then return {} end
    return {
        {
            x = fz.x, y = fz.y, w = fz.w, h = fz.h,
            id = "skills:__disclosure",
            isDisclosure = true,
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on the chevron, mouse parity).
            onActivate = function(w, el)
                w._skillsGridExpanded = not w._skillsGridExpanded
                w._skillsCache = nil  -- recompute scroll measurement
            end,
        },
    }
end

-- Skill rows — A or X opens the row's menu (skillRowMenu). Guard on
-- _skillsGridExpanded: when the grid is collapsed, the draw loop skips the
-- skill rows entirely and _skillRowZones is not refreshed; returning [] here
-- prevents the ring from holding phantom focusables at stale coords.
-- (the rows' callbacks: made once, not once a row a frame; each reads the row from el)
local function _skillRowOnFocus(w, el)
    w._gpFocusedSkill = el.skillName
end
-- A or X: the row's menu, with Pin to title bar (a press never pins on its own)
local function _skillRowOnActivate(w, el)
    if el.skillName then skillRowMenu(w, el.skillName, w:getAbsoluteX() + el.x + 40, w:getAbsoluteY() + el.y + el.h) end
end
-- the one column (a narrow card): Left and Right do nothing;
-- Down and Up go through the column (cone-nav)
local function _skillRowOnDpadDir(w, el, dir)
    if w._skillsOneCol and (dir == "left" or dir == "right") then return true end
    return false
end
local _skillRowIds = {}   -- (each row's id, "skill:<name>", made once)
local function _buildSkillRowFocusables(win)
    if not win or not win._skillsGridExpanded then return {} end
    local zones = win._skillRowZones
    if not zones or #zones == 0 then return {} end
    local elements = {}
    local TF = ZeD.TabFind
    for i = 1, #zones do
        local z = zones[i]
        local skillName = z.name
        -- (a row the Find text dims is no stop: the hand skips it)
        if TF and TF.skillOff(win, skillName) then skillName = nil end
        if skillName then
        local id = skillName and _skillRowIds[skillName]
        if not id then
            id = "skill:" .. tostring(skillName or i)
            if skillName then _skillRowIds[skillName] = id end
        end
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = id,
            skillName = skillName,
            onFocus = _skillRowOnFocus,
            onActivate = _skillRowOnActivate,
            onContextMenu = _skillRowOnActivate,
            onDpadDir = _skillRowOnDpadDir,
            dpadExits = true,   -- (the handler says false for every move it does not hold: the D-pad leaves)
        }
        end
    end
    -- Seed only when unset (this builder runs every frame).
    if elements[1] and elements[1].skillName and win._gpFocusedSkill == nil then
        win._gpFocusedSkill = elements[1].skillName
    end
    return elements
end

-- Training material chevrons. A toggles expansion + invalidates
-- _skillsCache so scroll height recomputes on the next render (mirrors the
-- mouse handler). No _skillsGridExpanded guard: the training section always
-- draws regardless of whether the XP grid is collapsed.
local function _trainingOnFocus(w, el)
    w._gpFocusedTraining = el.trainingId
end
local function _trainingOnActivate(w, el)
    if not el.trainingId then return end
    w._trainingExpanded = w._trainingExpanded or {}
    w._trainingExpanded[el.trainingId] = not w._trainingExpanded[el.trainingId]
    w._skillsCache = nil  -- force scroll height recalc
end
local _trainingIds = {}   -- (each row's id, "training:<key>", made once)
local function _buildTrainingChevronFocusables(win)
    local zones = win and win._trainingGroupZones
    if not zones or #zones == 0 then return {} end
    local elements = {}
    local TF = ZeD.TabFind
    for i = 1, #zones do
        local z = zones[i]
        local id = z.id and _trainingIds[z.id]
        if not id then
            id = "training:" .. tostring(z.id or i)
            if z.id then _trainingIds[z.id] = id end
        end
        -- (a row the Find text dims is no stop; z.label is the row's skill id)
        if not (TF and TF.trainOff(win, z.label)) then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = id,
                trainingId = z.id,
                onFocus = _trainingOnFocus,
                onActivate = _trainingOnActivate,
            }
        end
    end
    return elements
end

-- Skills tab aggregator. Disclosure first (tree-nav), then skill rows
-- (when grid expanded), then training chevrons (always). Cone-nav uses
-- spatial bounds, so interleaving collapsed-state content is safe.
-- the first match after the keyboard's Accept: a skill row (a dimmed row is no stop at all)
local function _skillsFindHit(el) return el.skillName ~= nil end

local function _buildSkillsFocusables(win)
    if not win then return {} end
    local elements = _buildSkillsDisclosureFocusable(win)
    -- the Find field in the heading, at its right (and, with nothing matching, the Clear key)
    local TF = ZeD.TabFind
    if TF then TF.stops(win, "skills", elements) end
    -- the keys a mod's head block stamped (ZeD.SkillsTab.stampStop), right after the disclosure
    local stops = win._skillsStops
    for i = 1, stops and stops.n or 0 do
        local s = stops[i]
        elements[#elements + 1] = {
            x = s.x, y = s.y, w = s.w, h = s.h,
            id = "skills:stop:" .. tostring(s.id),
            skillsStopId = s.id,
            onActivate = function(w) if s.onPress then s.onPress(w) end end,
        }
    end
    local rows = _buildSkillRowFocusables(win)
    for i = 1, #rows do elements[#elements + 1] = rows[i] end
    local chevs = _buildTrainingChevronFocusables(win)
    for i = 1, #chevs do elements[#elements + 1] = chevs[i] end
    if TF then
        -- Up from the top rows reaches a mod's key line before the heading; the field is
        -- above the key, the key above the rows (TabFind.skillsPadOrder)
        TF.skillsPadOrder(elements)
        TF.land(win, "skills", elements, _skillsFindHit)
    end
    return elements
end

-- The inventory rows' stops, for the active container's item list. Reads the
-- flat item array from the content panel's InventoryRenderer output
-- (`content._invRowItems`) and returns one stop per item. The renderer paints
-- the accent fill directly when it sees _gpFocusedRowItem.
--
-- onFocus: writes the focused item to both `win` and `content` so the renderer
-- can paint the accent fill and drive scroll-follow without a reverse
-- reference. The context menu goes through the vanilla
-- ISInventoryPaneContextMenu.createMenu entry point; Overrides/ContextMenu.lua
-- transforms it into the ZeD organism, docked bottom-center on a pad.
_buildInvRowFocusables = function(win)
    local c = win and win._mainContent
    local items = c and c._invRowItems
    if not items or #items == 0 then return {} end
    local elements = {}
    -- Bounds must be distinct per element so the cone-nav algorithm can
    -- pick neighbors. Prefer the renderer-stamped Y from _itemRenderYMap
    -- (keyed by the Java item itself); fall back to index*rowH when the
    -- map hasn't been populated yet (first frame / non-loot tab).
    local T = ZeD.T
    local rowH = (T and T.rowH) or 26
    local yMap = c._itemRenderYMap or {}
    local xMap = c._itemRenderXMap or {}   -- (the grid: each cell's x)
    local gcell = c._gridCell
    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            x = (xMap[item] or 0), y = yCoord, w = gcell or T.px(200), h = gcell or rowH,
            id = "invrow:" .. tostring(i),
            item = item,
            itemIndex = i,
            onFocus = function(w, el)
                -- Dual-write: renderer reads content._gpFocusedRowItem for
                -- accent paint + scroll-follow; win carries the reference for
                -- the per-frame refresh's identity-preservation logic.
                w._gpFocusedRowItem = el.item
                local cnt = w._mainContent
                if cnt then cnt._gpFocusedRowItem = el.item end
                -- Card follow-focus. When the drawer is open in "item"
                -- mode, moving the gp cursor to a different inv row live-swaps
                -- the card to the newly-focused item (no click needed).
                -- _updateDrawer is a plain function stored on win, NOT a
                -- method. Call with dot syntax — colon adds `self` as first arg
                -- and makes contentPanel = the window, which crashes.
                if w._drawerMode == "item" and w._updateDrawer and el.item and cnt and not w._gpPaint then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer(cnt)
                end
            end,
            -- A tap = LMB = SELECT item (opens the card drawer for it,
            -- mouse-click parity). On a stack rep (count > 1), A toggles
            -- the stack expand/collapse instead (= LMB on the chevron).
            -- X = RMB = open vanilla context menu (Drop, Grab, Move-To,
            -- etc.); for stack reps the menu receives ALL stack items so
            -- "Grab one / half / all" variants surface. X hold = double-LMB
            -- (InventoryRenderer.quickUse: a thing in a bag to the main
            -- inventory, else eat/wear/equip via vanilla
            -- ISInventoryPane:doContextualDblClick). A hold marks (below).
            onActivate = function(w, el)
                if not el.item then return end
                local cnt = w._mainContent
                local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                if stk and stk.count > 1 then
                    cnt._expandedStacks = cnt._expandedStacks or {}
                    cnt._expandedStacks[stk.key] = not cnt._expandedStacks[stk.key]
                    return
                end
                if cnt and w._updateDrawer then
                    ZeD.InventoryRenderer.padClearMarks(w, el, true)   -- (the marks drop, every list's)
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- A toggles the card drawer. Pressing A on the item
                    -- already shown clears the selection → updateDrawer closes
                    -- the card. Otherwise select this item → updateDrawer
                    -- opens (or live-swaps if already open on a different item).
                    if w._drawerItem ~= el.item then
                        sel[el.item] = true
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = el.item
                    else
                        cnt._selectedItems   = sel  -- empty after the clear
                        cnt._lastClickedItem = nil
                    end
                    w._updateDrawer(cnt)
                    -- the card opened (or swapped to this item):
                    -- focus onto its primary action, so A again does it
                    if w._drawerItem == el.item then ZeD.Input.Focus.focusPrimarySoon(w, "charItemCard", 2) end
                end
            end,
            -- the controller's marks: hold A marks, a held A paints, hold X is the quick use,
            -- B clears the marks (its prompt and X's only while marks exist, read each frame)
            onHoldActivate = function(w, el) ZeD.InventoryRenderer.padMark(w, el) end,
            onPaint        = function(w, el, paint) ZeD.InventoryRenderer.padPaint(w, el, paint) end,
            onHoldContext  = function(w, el)
                if not el.item then return end
                pcall(ZeD.InventoryRenderer.quickUse, el.item, ZeD.playerNumOf(w))
            end,
            onCancel   = ZeD.InventoryRenderer.padCancel,      -- B clears the marks (nothing without them)
            promptB    = ZeD.InventoryRenderer.padPromptB,     -- the footer reads these each frame (functions)
            promptX    = ZeD.InventoryRenderer.padPromptX,
            promptHold = ZeD.InventoryRenderer.padPromptHold,
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local stk = cnt and cnt._stacks and cnt._stacks[el.item]
                    local itemsArr = ZeD.InventoryRenderer.padMarkedItems(w, el) or ((stk and stk.count > 1) and stk.items or {el.item})
                    ISInventoryPaneContextMenu.createMenu(ZeD.playerNumOf(w), true, itemsArr, 0, 0)
                end
            end,
        }
    end
    -- Seed first-item focus so accent paints immediately on section enter
    -- (before D-pad fires its first onFocus).
    -- Seed only when nothing is remembered: a rebuild (scroll, an item gone)
    -- must not send focus back to the first row.
    if elements[1] and elements[1].item and win._gpFocusedRowItem == nil then
        win._gpFocusedRowItem = elements[1].item
        local cnt = win._mainContent
        if cnt then cnt._gpFocusedRowItem = elements[1].item end
    end
    -- rows out of the list's view: for the list's own Up / Down only
    ZeD.Input.Focus.markOffscreen(elements, c._rowView)
    -- the column's view button (up from the first row reaches it)
    for _, e in ipairs(ZeD.InventoryRenderer.toggleElements(c._viewToggleRects)) do elements[#elements + 1] = e end
    return elements
end

-- One MC column's stops, for the column `slot` names (1..#_mcSelected). Each
-- MC selection is its own ring zone (charMC1..charMCN) that the bumpers cycle
-- like any other; the last rendered column (main when visible, else the
-- rightmost bag) belongs to charMainInv instead. Single-column states
-- (main-only, or one MC bag with main hidden) return {} — charMainInv covers
-- the whole view and this zone goes non-focusable.
--
-- Bounds: x = cs.renderX (panel-local), y = per-row yMap stamp (saved per
-- column by renderMultiColumnContent's save-back block), w = cs.renderW,
-- h = rowH. Distinct x per column gives cone-nav cross-column spatial hops;
-- distinct y per row within a column gives intra-column D-pad.
--
-- Behavior mirrors the charMainInv element shape — the same tap / hold /
-- menu callbacks. onFocus writes the focused item into
-- content._gpFocusedRowItem so InventoryRenderer's accent-fill cue paints on
-- the right row (the renderer's cue is gated on the focused ring zone being
-- a mainInv or MC zone). Also writes win._gpFocusedMCItem +
-- win._gpFocusedMCColIdx for scroll-follow dispatch and MC zone state
-- (tree-nav, card follow-focus).
_buildCharacterMCColumnFocusables = function(win, slot)
    if not win or win._activeTab ~= "loot" then return {} end
    if not slot then return {} end
    local mcSel = win._mcSelected or {}
    if slot < 1 or slot > #mcSel then return {} end
    local content = win._mainContent
    if not content then return {} end
    local colStates = content._colStates
    if not colStates or slot > #colStates then return {} end

    local cs = colStates[slot]
    if not cs then return {} end

    local elements = {}
    local T = ZeD.T
    local rowH  = (T and T.rowH) or 26
    local items = cs.flatItems or {}
    local yMap  = cs.itemRenderYMap or {}
    local xMap  = cs.itemRenderXMap or {}   -- (the grid: each cell's x)
    local gcell = cs.gridCell
    local colX  = cs.renderX or 0
    local colW  = cs.renderW or T.px(200)

    for i = 1, #items do
        local item = items[i]
        local yCoord = yMap[item] or (i * rowH)
        elements[#elements + 1] = {
            x = (xMap[item] or colX), y = yCoord, w = gcell or colW, h = gcell or rowH,
            id = "mcrow:" .. slot .. ":" .. tostring(i),
            item = item,
            itemIndex = i,
            colIdx = slot,
            mcSlot = slot,
            containerIdx = cs.containerIdx,
            onFocus = function(w, el)
                local cnt = w._mainContent
                if cnt then cnt._gpFocusedRowItem = el.item end
                w._gpFocusedMCItem   = el.item
                w._gpFocusedMCColIdx = el.colIdx
                if w._drawerMode == "item" and w._updateDrawer and el.item and cnt and not w._gpPaint then
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    sel[el.item] = true
                    cnt._selectedItems   = sel
                    cnt._lastClickedItem = el.item
                    w._updateDrawer(cnt)
                end
            end,
            -- A = LMB. Stack rep → toggle expand/collapse; non-stack
            -- item → select (open card drawer). X = RMB = vanilla context
            -- menu (Drop/Grab/etc.); hold X = double-LMB use; hold A marks.
            onActivate = function(w, el)
                if not el.item then return end
                local cnt = w._mainContent
                local cs2 = cnt and cnt._colStates and cnt._colStates[el.colIdx]
                local stk = cs2 and cs2.stacks and cs2.stacks[el.item]
                if stk and stk.count > 1 then
                    cs2.expandedStacks = cs2.expandedStacks or {}
                    cs2.expandedStacks[stk.key] = not cs2.expandedStacks[stk.key]
                    return
                end
                if cnt and w._updateDrawer then
                    ZeD.InventoryRenderer.padClearMarks(w, el, true)   -- (the marks drop, every list's)
                    local sel = cnt._selectedItems or {}
                    for k in pairs(sel) do sel[k] = nil end
                    -- A toggles the card drawer (as on the main list's rows).
                    if w._drawerItem ~= el.item then
                        sel[el.item] = true
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = el.item
                    else
                        cnt._selectedItems   = sel
                        cnt._lastClickedItem = nil
                    end
                    w._updateDrawer(cnt)
                    -- the card opened: focus onto its primary action
                    if w._drawerItem == el.item then ZeD.Input.Focus.focusPrimarySoon(w, "charItemCard", 2) end
                end
            end,
            -- the controller's marks: hold A marks, a held A paints, hold X is the quick use,
            -- B clears the marks (its prompt and X's only while marks exist, read each frame)
            onHoldActivate = function(w, el) ZeD.InventoryRenderer.padMark(w, el) end,
            onPaint        = function(w, el, paint) ZeD.InventoryRenderer.padPaint(w, el, paint) end,
            onHoldContext  = function(w, el)
                if not el.item then return end
                pcall(ZeD.InventoryRenderer.quickUse, el.item, ZeD.playerNumOf(w))
            end,
            onCancel   = ZeD.InventoryRenderer.padCancel,      -- B clears the marks (nothing without them)
            promptB    = ZeD.InventoryRenderer.padPromptB,     -- the footer reads these each frame (functions)
            promptX    = ZeD.InventoryRenderer.padPromptX,
            promptHold = ZeD.InventoryRenderer.padPromptHold,
            onContextMenu = function(w, el)
                if not el.item then return end
                if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
                    local cnt = w._mainContent
                    local cs2 = cnt and cnt._colStates and cnt._colStates[el.colIdx]
                    local stk = cs2 and cs2.stacks and cs2.stacks[el.item]
                    local itemsArr = ZeD.InventoryRenderer.padMarkedItems(w, el) or ((stk and stk.count > 1) and stk.items or {el.item})
                    ISInventoryPaneContextMenu.createMenu(ZeD.playerNumOf(w), true, itemsArr, 0, 0)
                end
            end,
        }
    end
    -- rows out of the column's view: for the column's own Up / Down only
    ZeD.Input.Focus.markOffscreen(elements, cs.rowView)
    -- the column's view button
    for _, e in ipairs(ZeD.InventoryRenderer.toggleElements(cs.viewToggleRects)) do elements[#elements + 1] = e end
    -- An empty MC column needs a placeholder so the zone stays focusable;
    -- otherwise the bumpers skip empty containers.
    if #elements == 0 then
        elements[1] = {
            x = colX, y = 0, w = colW, h = rowH,
            id = "mcempty:" .. slot,
            item = nil,
            colIdx = slot,
            mcSlot = slot,
            containerIdx = cs.containerIdx,
            isPlaceholder = true,
            onFocus = function(w, el)
                w._gpFocusedMCItem   = nil
                w._gpFocusedMCColIdx = el.colIdx
            end,
            onActivate    = function(w, el) end,
            onHoldActivate = function(w, el) end,
            onContextMenu = function(w, el) end,
        }
    end
    return elements
end

-- True when a Loot column's pad targets need rebuilding: its rows (the same
-- items in the same order), scroll, view, row height, place or container
-- changed since the last build. Records the new state when it says yes.
-- No tables or strings are made on the frames where nothing changed.
local function _charMCColumnDirty(win, slot, cs)
    win._lastMCSnap = win._lastMCSnap or {}
    local snap = win._lastMCSnap[slot]
    local items = cs.flatItems or {}
    local n = #items
    local scrollPos = cs.scroll and cs.scroll.scrollPos
    local yMap = cs.itemRenderYMap
    local y1 = yMap and n > 0 and yMap[items[1]] or nil
    local nToggles = (cs.viewToggleRects and #cs.viewToggleRects or 0) + 4096 * ZeD.InventoryRenderer.filterGen(win._mainContent)   -- (the Filter's stops move)
    if snap and snap.n == n and snap.scrollPos == scrollPos and snap.y1 == y1
       and snap.gridCell == cs.gridCell and snap.renderX == cs.renderX
       and snap.renderW == cs.renderW and snap.rowH == ZeD.T.rowH
       and snap.containerIdx == cs.containerIdx and snap.nToggles == nToggles
       and snap.vb == (cs.rowView and cs.rowView.bottom) then   -- (the view: which rows are out of it)
        local same = true
        local old = snap.items
        for i = 1, n do
            if old[i] ~= items[i] then same = false; break end
        end
        if same then return false end
    end
    local copy = {}
    for i = 1, n do copy[i] = items[i] end
    win._lastMCSnap[slot] = {
        n = n, items = copy, scrollPos = scrollPos, y1 = y1,
        gridCell = cs.gridCell, renderX = cs.renderX, renderW = cs.renderW,
        rowH = ZeD.T.rowH, containerIdx = cs.containerIdx, nToggles = nToggles,
        vb = cs.rowView and cs.rowView.bottom,
    }
    return true
end

-- Per-frame refresh of the Loot tab's per-column charMC<n> zones. Each column
-- is rebuilt only when it changed (_charMCColumnDirty): rebuilding every column
-- every frame made a table, an id string and four closures per row, for
-- mouse players too. Focus is kept on the same item across a rebuild, or on the
-- same view or Filter stop (keepToggleIdx: a press on the Filter bar rebuilds it).
local function _refreshCharMCZones(win, Focus)
    if win._activeTab ~= "loot" then
        win._lastMCSnap = nil  -- the zones are rebuilt on the way back
        return
    end
    local mcSel = win._mcSelected or {}
    local content = win._mainContent
    local colStates = content and content._colStates
    for slot = 1, #mcSel do
        local cs = colStates and colStates[slot]
        if not cs or _charMCColumnDirty(win, slot, cs) then
            local zoneName = "charMC" .. slot
            local newEls = _buildCharacterMCColumnFocusables(win, slot) or {}
            local preserveIdx = 1
            if #newEls > 0 and win._gpFocusedMCItem then
                for i, el in ipairs(newEls) do
                    if el.item == win._gpFocusedMCItem then
                        preserveIdx = i
                        break
                    end
                end
            end
            preserveIdx = ZeD.InventoryRenderer.keepToggleIdx(win, zoneName, newEls, preserveIdx)
            Focus.setRingZoneElements(win, zoneName, newEls, preserveIdx)
            Focus.setZoneFocusable   (win, zoneName, #newEls > 0)
        end
    end
end

-- Item card action strip focusables. Delegates to the card organism, which
-- stamps live button rects (absolute screen coords) each frame via
-- M14 drawActionStrip / M16 drawVerbStrip. Element order is the card's own
-- (ZeD_ItemCard:getActionStripElements): a running action's cancel, the
-- header verbs, the name row, the folded care verbs, the FAV / PROTECT /
-- UNWANTED marks and the Lists mark, then the verbs (repair and the like).
-- Returns {} when no card is open (win._drawerItem nil).
--
-- Each card button gets:
--   * onDpadDir — Up / Down go through ZeD_ItemCard:gpDpad (see below);
--     L/R fall through to flat cone-nav between buttons.
--   * onCancel  — B closes the card drawer (mouse parity = X-button on
--     window chrome / ESC key path).
_buildCardActionFocusables = function(win)
    if not (win and win._itemCard) then return {} end
    -- Gate on card visibility, not mode. The card overlays the tab
    -- drawer on non-Loot tabs while _drawerMode stays "tab"; in that state
    -- the buttons are still painted and must remain interactive. Mirrors
    -- World's _buildWorldCardActionFocusables.
    if win._drawerItem == nil then return {} end
    local els = win._itemCard:getActionStripElements() or {}
    -- Append the clothing detail-zone structural docks AFTER the action strip.
    -- Natural D-pad order: action strip → zone docks. Greyed/pristine docks are
    -- not in _zoneDockRects so they're auto-skipped (no focus, no activation).
    local dockEls = win._itemCard:getZoneDockElements() or {}
    for i = 1, #dockEls do els[#els + 1] = dockEls[i] end
    -- ItemCard returns ABSOLUTE screen coords (Molecules.lua
    -- drawActionStrip: `rects[i] = {x = absX + bx, ...}`).
    -- _collectFlat translates panel-local → window-local by adding the
    -- panel's getX/Y, which double-offsets these and pushes the focusables
    -- way off-screen — cone-nav can't reach them and B's onCancel never
    -- fires because focus never actually lands on a card button. Convert
    -- absolute → panel-local here so _collectFlat's translation is correct.
    local drawerPanel = win._itemDrawerPanel
    local panelAbsX = (drawerPanel and drawerPanel.getAbsoluteX
                       and drawerPanel:getAbsoluteX()) or 0
    local panelAbsY = (drawerPanel and drawerPanel.getAbsoluteY
                       and drawerPanel:getAbsoluteY()) or 0
    for i = 1, #els do
        local el = els[i]
        el.x = el.x - panelAbsX
        el.y = el.y - panelAbsY
        -- Up = to the action strip, Down = next control, then
        -- read on (ZeD_ItemCard:gpDpad, shared with the World window);
        -- L/R fall through to the spatial move
        el.onDpadDir = function(w, e, dir)
            if w._itemCard and w._itemCard.gpDpad then
                return w._itemCard:gpDpad(w, e, dir, "charItemCard")
            end
            return false
        end
        el.onCancel = function(w, e)
            -- Close drawer (mirrors mouse-click on a non-card area / ESC).
            local content = w._mainContent
            if content and w._updateDrawer then
                local sel = content._selectedItems or {}
                for k in pairs(sel) do sel[k] = nil end
                content._selectedItems   = sel
                content._lastClickedItem = nil
                w._updateDrawer(content)
            end
        end
    end
    return els
end

-- The list's and the doll's stops share their callbacks: made once, not once a stop a frame
-- (the builder below runs every frame the stops are kept fresh); each reads its stop from el.
local function _equipStopOnFocus(w, el) w._gpFocusedEquipSlot = el.slotType end
local function _equipPartOnFocus(w, el)
    w._equipDefHoveredPart = el.partName
    w._gpFocusedEquipSlot = el.slotType
end
local function _equipDollDpad(w, el, dir) return ZeD.EquipDoll.dpad(w, el, dir) end
local function _equipGroupOnActivate(w, el)
    w._equipExpanded = w._equipExpanded or {}
    w._equipExpanded[el.groupId] = not w._equipExpanded[el.groupId]
end
local function _equipSlotOnActivate(w, el)
    w._equipSelected = el.slotType
    w._equipCache = nil
    w._gpFocusedEquipSlot = nil  -- reseed to card back button
    -- Race guard: the card renderer fires AFTER this prerender,
    -- so on frame N the real back/action bounds aren't stamped
    -- yet. Without fallback bounds the first D-pad press after
    -- A is eaten (cone-nav on an empty ring is silent).
    -- Pre-stamp approximate bounds so cone has something to
    -- work with; real values overwrite next frame.
    if not (w._equipBackBtnZone and (w._equipBackBtnZone.w or 0) > 0) then
        local Tk = ZeD.T
        local dW = math.floor(w._drawerEffW or Tk.px(220))
        w._equipBackBtnZone = { x = dW - Tk.px(108), y = Tk.px(4), w = Tk.px(100), h = Tk.buttonH }
    end
    if not (w._equipActionZones and #w._equipActionZones > 0) then
        local Tk = ZeD.T
        local dW = math.floor(w._drawerEffW or Tk.px(220))
        local ay, bw, gap = Tk.px(260), Tk.px(70), Tk.px(4)
        w._equipActionZones = {
            { x = dW - Tk.px(10) - (bw * 2 + gap), y = ay, w = bw, h = Tk.buttonH, id = "drop" },
            { x = dW - Tk.px(10) - bw,             y = ay, w = bw, h = Tk.buttonH, id = "unequip" },
        }
    end
end
local function _equipSlotOnContextMenu(w, el)
    -- Gamepad X opens the same ZeD context menu RMB does
    -- (parity with inv-row context menu pattern). Anchored at the
    -- focused slot row's screen position.
    if not el.item then return end
    local playerObj = getSpecificPlayer(ZeD.playerNumOf(w))
    if not playerObj then return end
    local pNum = playerObj:getPlayerNum()
    local inv  = playerObj:getInventory()
    local isInInv = inv:isInCharacterInventory(playerObj)
    -- Anchor at the slot row's center.
    local drawerPanel = w._itemDrawerPanel
    local panelAbsX = (drawerPanel and drawerPanel.getAbsoluteX
                       and drawerPanel:getAbsoluteX()) or 0
    local panelAbsY = (drawerPanel and drawerPanel.getAbsoluteY
                       and drawerPanel:getAbsoluteY()) or 0
    local mx = panelAbsX + (el.x or 0) + math.floor((el.w or 0) / 2)
    local my = panelAbsY + (el.y or 0) + math.floor((el.h or 0) / 2)
    ISInventoryPaneContextMenu.createMenu(
        pNum, isInInv, { el.item }, mx, my
    )
end
local function _equipBeltOnActivate(w, el)
    local p = w._itemDrawerPanel
    local b = el.zone.btn
    local ax = (p and p:getAbsoluteX() or 0) + b.x + math.floor(b.w / 2)
    local ay = (p and p:getAbsoluteY() or 0) + b.y
    ZeD.EquipmentTab.beltAction(w, el.zone, ax, ay)
end
local function _equipBeltOnContextMenu(w, el)
    local p = w._itemDrawerPanel
    local ax = (p and p:getAbsoluteX() or 0) + el.x + math.floor(el.w / 2)
    local ay = (p and p:getAbsoluteY() or 0) + el.y
    if el.zone.item then
        ISInventoryPaneContextMenu.createMenu(ZeD.playerNumOf(w), true, { el.zone.item }, ax, ay)
    elseif ZeD.Belt then
        ZeD.Belt.slotMenu(ZeD.playerNumOf(w), el.zone.i, ax, ay)
    end
end

-- Equipment tab focusables. Ring zone `charTabContent` treats the
-- equipment drawer as a single flow: disclosure at the top, equipment slots
-- below. D-pad up/down cones navigate between them; A on the disclosure
-- shows or hides the equipped slot list; A on a slot enters card mode (same
-- as a click). Stat rows are pure readout, never focusable. LB/RB only move
-- between ring zones, never between these stops.
--
-- Card mode (win._equipSelected ~= nil): the stops become the card's own
-- buttons (the CARD MODE branch below; stand-ins for back + Drop / Unequip
-- until the card has drawn). Entering and exiting card mode nils
-- _gpFocusedEquipSlot so the seed path picks the first element of the new
-- element set.
-- the first match after the keyboard's Accept: a slot with a thing in it (dimmed slots are no stops)
local function _equipFindHit(el) return el.item ~= nil end

local function _buildEquipmentFocusables(win)
    -- the loadouts' to-do holds the drawer (ZeD_EquipLoadout): its stops alone
    if win and ZeD.EquipLoadout and ZeD.EquipLoadout.todoOpen(win) then return ZeD.EquipLoadout.focusables(win) end
    local elements = {}

    -- CARD MODE branch: the Equip tab's own item card (a ZeD_ItemCard in the
    -- drawer). Its buttons, as the inventory's card offers them: the header
    -- verbs (Unequip, Drop...), the marks, the repair verbs, the clothing docks,
    -- then the back arrow and a doll card's layer strip. The card stamps screen
    -- coords; the zone's panel is the drawer. B goes back to the list / doll.
    -- (These are the card's real rects: with stand-ins here, the pad never
    -- reached the card's real buttons.)
    local eqCard = win and win._equipSelected and win._drawerPanel and win._drawerPanel._equipCard
    if eqCard and eqCard:isVisible() and eqCard.item then
        local dp = win._drawerPanel
        local dax, day = dp:getAbsoluteX(), dp:getAbsoluteY()
        local function back(w)
            w._equipSelected = nil
            w._gpFocusedEquipSlot = nil
        end
        local raw = eqCard:getActionStripElements() or {}
        for _, e in ipairs(eqCard:getZoneDockElements() or {}) do raw[#raw + 1] = e end
        for _, e in ipairs(raw) do
            local orig = e.onFocus
            elements[#elements + 1] = {
                x = e.x - dax, y = e.y - day, w = e.w, h = e.h,
                id = "equipcard:" .. tostring(e.id),
                slotType = "__card_" .. tostring(e.id),
                onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType; if orig then orig() end end,
                onActivate = e.onActivate,
                onCancel = back,
                onDpadDir = function(w, el, dir)
                    if dir == "up" and eqCard.scrollToPrevDisclosure then eqCard:scrollToPrevDisclosure(); return end
                    if dir == "down" and eqCard.scrollToNextDisclosure then eqCard:scrollToNextDisclosure(); return end
                    return false
                end,
            }
        end
        local bb = eqCard._backBarRects and eqCard._backBarRects.back
        if bb and bb.x then
            local cax, cay = eqCard:getAbsoluteX(), eqCard:getAbsoluteY()
            elements[#elements + 1] = {
                x = cax + bb.x - dax, y = cay + bb.y - day, w = bb.w, h = bb.h,
                id = "equipcard:back", slotType = "__card_back",
                onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType; eqCard._gpFocusedBtnId = nil end,
                onActivate = back, onCancel = back,
            }
        end
        for _, z in ipairs(win._equipLayerZones or {}) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "equipcard:" .. z.key, slotType = z.key, dir = z.dir,
                onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType; eqCard._gpFocusedBtnId = nil end,
                onActivate = function(w, el) ZeD.EquipDoll.stepLayer(w, el.dir) end,
                onCancel = back,
            }
        end
        -- a card just opened: focus starts on its first button (the main verb),
        -- and B later returns to the slot or row it came from
        if elements[1] and win._equipCardSeed ~= win._equipSelected then
            win._equipCardSeed = win._equipSelected
            elements._focusIdx = 1
            win._gpFocusedEquipSlot = nil
        end
        if elements[1] and win._gpFocusedEquipSlot == nil then
            win._gpFocusedEquipSlot = elements[1].slotType
            if elements[1].onFocus then elements[1].onFocus(win, elements[1]) end
        end
        return elements
    end
    if win and win._equipSelected then
        -- (the card's first frame, before it has drawn: the stand-ins below)
        -- Prefer the button-shaped bounds (_equipBackBtnZone) for cone nav so
        -- D-pad down from back lands on the nearest action button. Fall back
        -- to the full-header zone if the button-specific stamp isn't ready.
        local bz = win._equipBackBtnZone or win._equipBackZone
        if bz and (bz.w or 0) > 0 then
            elements[#elements + 1] = {
                x = bz.x, y = bz.y, w = bz.w, h = bz.h,
                id = "equipcard:back",
                slotType = "__back",
                onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType end,
                onActivate = function(w, _)
                    w._equipSelected = nil
                    w._gpFocusedEquipSlot = nil
                end,
            }
        end
        local azs = win._equipActionZones
        if azs then
            for i = 1, #azs do
                local z = azs[i]
                elements[#elements + 1] = {
                    x = z.x, y = z.y, w = z.w, h = z.h,
                    id = "equipcard:" .. tostring(z.id or i),
                    slotType = "__btn_" .. tostring(z.id or i),
                    actionId = z.id,
                    onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType end,
                    onActivate = function(w, el)
                        local data = w._equipCache
                        if not data or not data.groups then return end
                        local selSlot
                        for _, g in ipairs(data.groups) do
                            for _, s in ipairs(g.slots) do
                                if s.type == w._equipSelected then
                                    selSlot = s; break
                                end
                            end
                            if selSlot then break end
                        end
                        if selSlot and ZeD.EquipmentTab and ZeD.EquipmentTab._handleAction then
                            ZeD.EquipmentTab._handleAction(w, el.actionId, selSlot)
                            -- If the action exited card mode, clear gp focus so
                            -- the list-mode seed lands on disclosure.
                            if not w._equipSelected then
                                w._gpFocusedEquipSlot = nil
                            end
                        end
                    end,
                }
            end
        end

        if elements[1] and win._gpFocusedEquipSlot == nil then
            win._gpFocusedEquipSlot = elements[1].slotType
        end
        return elements
    end

    -- LIST MODE branch
    -- Equipment body-figure part focusables, in LIST mode. Mirrors the
    -- Health/Thermal pattern — parts drive the defense detail readout via
    -- _equipDefHoveredPart. A is a no-op (readout only). Built inline as a
    -- local helper rather than one more forward-declaration at file scope.
    local function _buildEquipBodyParts()
        -- The defense body figure has no disclosure of its own (it shows at
        -- the bottom of the tab), so its parts are pickable whenever it is drawn.
        if not win then return end
        -- (the Defense block hides while the Find field holds text: its parts are no stops then)
        if win._equipDefHidden then return end
        local fig = win._equipDefBodyFigure
        if not fig or not fig.getPartRects then return end
        local rects = fig:getPartRects()
        if not rects or #rects == 0 then return end
        for i = 1, #rects do
            local r = rects[i]
            elements[#elements + 1] = {
                x = r.x, y = r.y, w = r.w, h = r.h,
                id = "equippart:" .. tostring(r.name),
                slotType = "__part_" .. tostring(r.name),
                partName = r.name,
                onFocus = _equipPartOnFocus,
                -- onActivate omitted — body part is readout only, focus
                -- drives the right-column defense detail view.
            }
        end
    end

    -- Disclosure ("Equipped" header) — only if bounds are stamped. First
    -- frame after tab switch may miss the stamp; per-frame refresh catches up.
    -- Field name `_equipDefenseZone` retained for backward compat; it now
    -- points at the "Equipped" disclosure that toggles the slot list.
    local dz = win and win._equipDefenseZone
    if dz and (dz.w or 0) > 0 then
        elements[#elements + 1] = {
            x = dz.x, y = dz.y, w = dz.w, h = dz.h,
            id = "equipslot:__disclosure",
            slotType = "__disclosure",
            onFocus = function(w, el)
                w._gpFocusedEquipSlot = el.slotType
            end,
            -- A toggles expand/collapse of the equipped slot list (the
            -- disclosure once folded the defense body, hence the zone's name).
            onActivate = function(w, _)
                w._equipListExpanded = not w._equipListExpanded
            end,
        }
    end

    -- The Find field, between the heading's words and List | Doll (and the empty result's Clear)
    local TF = ZeD.TabFind
    if TF and win then TF.stops(win, "equip", elements) end

    -- The List | Doll toggle in the heading (EquipDoll.drawToggle). A picks the view.
    for _, z in ipairs(win and win._equipViewZones or {}) do
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = "equipview:" .. z.view, slotType = z.key, view = z.view,
            onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType end,
            onActivate = function(w, el)
                ZeD.EquipDoll.setView(el.view)
                w._equipListExpanded = true
            end,
        }
    end
    -- The body-figure parts go in between the disclosure and the group
    -- headers: disclosure → parts → group headers → slots. (Cone-nav picks
    -- by place on screen; this order only matters for the first-stop seed.)
    _buildEquipBodyParts()

    -- Group headers (HEAD+FACE, TORSO, etc.) — A toggles the group's
    -- expanded flag, showing/hiding empty slots in the list. Only shown
    -- when the slot list has been stamped this frame (gzones non-empty).
    local gzones = win and win._equipGroupZones
    if gzones then
        for i = 1, #gzones do
            local gz = gzones[i]
            -- (a group the Find text dims, nothing in it matching, is no stop)
            if not (TF and TF.equipGroupOff(win, gz.id)) then
            elements[#elements + 1] = {
                x = gz.x, y = gz.y, w = gz.w, h = gz.h,
                id = "equipgroup:" .. tostring(gz.id),
                slotType = "__group_" .. tostring(gz.id),
                groupId = gz.id,
                onFocus = _equipStopOnFocus,
                onActivate = _equipGroupOnActivate,   -- (A toggles the group, = LMB on the header)
            }
            end
        end
    end
    -- while the Find field holds text, only the matching slots are stops (the rest are dimmed)
    local finding = TF and win and TF.active(win, "equip")

    -- Equipment slots (only slots with equipped items get stamped).
    -- A matches mouse-click: enters inline card mode for the selected slot.
    -- X opens the worn item's context menu, as a right-click does.
    local zones = win and win._equipSlotZones
    if zones then
        for i = 1, #zones do
            local z = zones[i]
            if not (finding and TF.equipOff(win, z.type)) then
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "equipslot:" .. tostring(z.type or i),
                slotType = z.type,
                item = z.item,
                onFocus = _equipStopOnFocus,
                -- the doll: Left / Right cross the figure to the other column
                onDpadDir = _equipDollDpad,
                dpadExits = true,   -- (Up / Down and the doll's outer edge say false: the D-pad leaves)
                onActivate = _equipSlotOnActivate,
                onContextMenu = _equipSlotOnContextMenu,
            }
            end
        end
    end

    -- The belt's rows (HOOK_MAP rows 5 + 6, stamped by EquipmentTab under
    -- HELD + BELT). A runs the row's button (DETACH / PUT BACK, or ATTACH's
    -- list at the button); X opens the item's menu, or the slot's list when
    -- it is empty, at the row.
    local bzones = win and win._equipBeltZones
    if bzones and not finding then
        for i = 1, #bzones do
            local z = bzones[i]
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "equipbelt:" .. tostring(z.i),
                slotType = z.fid,
                zone = z,
                onFocus = _equipStopOnFocus,
                onActivate = _equipBeltOnActivate,
                onContextMenu = _equipBeltOnContextMenu,
            }
        end
    end

    -- The doll's empty slots: stops for the pad so moves keep to its columns
    -- and rows; nothing to open (no onActivate).
    for _, z in ipairs((not finding) and win and win._equipDollEmpty or {}) do
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = "equipslot:" .. z.type, slotType = z.type,
            onFocus = _equipStopOnFocus,
            onDpadDir = _equipDollDpad,
            dpadExits = true,   -- (Up / Down and the doll's outer edge say false: the D-pad leaves)
        }
    end

    -- the loadouts' fold under the doll and the lists (ZeD_EquipLoadout), and where the focus lands after its to-do
    if win and ZeD.EquipLoadout then ZeD.EquipLoadout.barFocusables(win, elements) end
    if win and ZeD.EquipLoadout then ZeD.EquipLoadout.land(win, elements) end
    -- Back from a card: focus returns to the slot or row that opened it
    if win and win._equipCardSeed and not win._equipSelected then
        local want = "equipslot:" .. tostring(win._equipCardSeed)
        win._equipCardSeed = nil
        for i, el in ipairs(elements) do
            if el.id == want then
                elements._focusIdx = i
                win._gpFocusedEquipSlot = el.slotType
                break
            end
        end
    end
    -- after a Find clear or the keyboard's Accept: the field, or the first matching slot
    if TF and win then TF.land(win, "equip", elements, _equipFindHit) end

    -- Seed only when unset — this builder runs every prerender frame and
    -- would otherwise stomp the D-pad's onFocus-written value each tick.
    if elements[1] and win._gpFocusedEquipSlot == nil then
        win._gpFocusedEquipSlot = elements[1].slotType
    end
    return elements
end

-- Health tab focusables: the footer band. In order: the
-- exercise pop-up box, the session time's - and +, Start (primary, last). With the
-- exercise list open the stops are its rows instead (the current exercise first; A
-- picks, B shuts it); shutting it returns the pad to the box. The band is pinned, so
-- its stops are bandStop (the body's scroll-follow ignores them). Start keeps the
-- focus after it is pressed (same id, nothing rebuilt).
local function _buildHealthBandFocusables(win)
    local bz = win and win._healthBand
    if not bz or not bz.box.w then return {} end
    local H = ZeD.HealthTab
    local elements = {}
    if win._healthMenuOpen and win._healthMenuZones then
        local sel = H.selectedExercise(win)
        for i, z in ipairs(win._healthMenuZones) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "health:menuRow:" .. tostring(z.id),
                menuRowId = z.id,
                onFocus = function(w, el) end,
                onActivate = function(w, el) H.closeMenu(w, el.menuRowId) end,
                onCancel = function(w, el) H.closeMenu(w) end,
            }
            if z.id == sel then elements._focusIdx = i end
        end
        elements._menuRows = true
        return elements
    end
    elements[1] = {
        x = bz.box.x, y = bz.box.y, w = bz.box.w, h = bz.box.h,
        id = "health:exercise", bandStop = true,
        onFocus = function(w, el) end,
        onActivate = function(w, el) H.openMenu(w) end,
    }
    elements[2] = {
        x = bz.dec.x, y = bz.dec.y, w = bz.dec.w, h = bz.dec.h,
        id = "health:time:dec", bandStop = true,
        onFocus = function(w, el) end,
        onActivate = function(w, el) H.stepMinutes(w, -10) end,
    }
    elements[3] = {
        x = bz.inc.x, y = bz.inc.y, w = bz.inc.w, h = bz.inc.h,
        id = "health:time:inc", bandStop = true,
        onFocus = function(w, el) end,
        onActivate = function(w, el) H.stepMinutes(w, 10) end,
    }
    elements[4] = {
        x = bz.start.x, y = bz.start.y, w = bz.start.w, h = bz.start.h,
        id = "health:start", bandStop = true,
        onFocus = function(w, el) end,
        onActivate = function(w, el) H.startSelected(w) end,
    }
    return elements
end

-- So that Down from the body figure always reaches the band, at every window size
-- and text size, a stop in a scrolling body counts only where the body shows it,
-- between the pinned header and the footer band (view = the tab's { x, y, w, h },
-- stamped each frame). A stop partly hidden is clipped to the view; one wholly out
-- of view is no stop, so nothing under the band is "below" the lowest stop shown,
-- and Down from it reaches the band. Focusing the lowest one shown scrolls the body
-- on (HealthTab's scroll-follow), and the stops under it come into view. Returns
-- y, h, or nil when the rect is out of view.
local function _inBodyView(view, y, h)
    if not view then return y, h end
    local top, bot = math.max(y, view.y), math.min(y + h, view.y + view.h)
    if bot - top < 2 then return nil end
    return top, bot - top
end

-- Health tab focusables: injury list rows. A opens the vanilla treatment
-- context menu for the entry's body part (the menu a right-click on the row
-- or the figure opens). Flat list; no per-entry disclosure.
-- (only the rows the body shows; fullY / fullH keep the row's whole rect)
local function _buildHealthInjuryFocusables(win)
    local zones = win and win._healthInjuryZones
    if not zones or #zones == 0 then return {} end
    local elements = {}
    local view = win._healthView
    for i = 1, #zones do
        local z = zones[i]
        local vy, vh = _inBodyView(view, z.y, z.h)
        if vy then elements[#elements + 1] = {
            x = z.x, y = vy, w = z.w, h = vh, fullY = z.y, fullH = z.h,
            id = "injury:" .. tostring(z.bodyPartName),
            injuryKey = z.bodyPartName,
            onFocus = function(w, el)
                w._gpFocusedInjury = el.injuryKey
            end,
            onActivate = function(w, el)
                if ZeD.HealthTab and ZeD.HealthTab._onPartClicked then
                    -- _onPartClicked falls back to w._healthContentPanel / w
                    -- when drawerPanel is nil.
                    ZeD.HealthTab._onPartClicked(w, el.injuryKey, nil, nil, nil)
                end
            end,
        } end
    end
    if elements[1] and win._gpFocusedInjury == nil then
        win._gpFocusedInjury = elements[1].injuryKey
    end
    return elements
end

-- Health tab focusables: body figure parts. A opens the vanilla
-- treatment context menu for the focused part (the menu a right-click on
-- the part opens). Only populated when the figure is expanded;
-- collapsed figure yields empty list and cone-nav flows around it.
local function _buildHealthBodyPartFocusables(win)
    if not win or not win._healthFigureExpanded then return {} end
    local fig = win._healthBodyFigure
    if not fig or not fig.getPartRects then return {} end
    local rects = fig:getPartRects()
    if not rects or #rects == 0 then return {} end
    -- Body figure is drawn inside the tab content panel at panel-local
    -- coords; the figure panel itself is never attached as a child (the
    -- figure uses :drawAt). getPartRects returns panel-local rects relative
    -- to the content panel, same coord space as exercises + injuries.
    -- (only the parts the body shows, clipped to it: _inBodyView)
    local elements = {}
    local view = win._healthView
    for i = 1, #rects do
        local r = rects[i]
        local vy, vh = _inBodyView(view, r.y, r.h)
        if vy then elements[#elements + 1] = {
            x = r.x, y = vy, w = r.w, h = vh, fullY = r.y, fullH = r.h,
            id = "bodypart:" .. tostring(r.name),
            partName = r.name,
            onFocus = function(w, el)
                w._gpFocusedBodyPart = el.partName
            end,
            onActivate = function(w, el)
                if ZeD.HealthTab and ZeD.HealthTab._onPartClicked then
                    ZeD.HealthTab._onPartClicked(w, el.partName, nil, nil, nil)
                end
            end,
        } end
    end
    if elements[1] and win._gpFocusedBodyPart == nil then
        win._gpFocusedBodyPart = elements[1].partName
    end
    return elements
end

-- Mouse path to the same treatment menu: right-click on the body figure or an
-- injury row opens vanilla's body-part menu (bandage, stitch, splint, remove
-- glass or bullet, disinfect, poultice, clean burn), the gesture vanilla's
-- health panel uses. Rows scrolled under the pinned header, the footer band and
-- the scrollbar do not count; an open exercise list is shut by the press instead.
-- Returns true when a part was hit.
local function _healthTreatAt(win, panel, x, y)
    if not (ZeD.HealthTab and ZeD.HealthTab._onPartClicked) then return false end
    if win._healthMenuOpen then ZeD.HealthTab.closeMenu(win); return false end
    if win._healthBandY and y >= win._healthBandY then return false end
    local fz = win._healthFigureZone
    if fz and y < fz.y + fz.h then return false end
    local sc = win._healthScroll
    if sc and sc.visible and x >= sc.x then return false end
    if win._healthFigureExpanded and win._healthBodyFigure then
        local part = win._healthBodyFigure:hitTestAt(x, y)
        if part then
            ZeD.HealthTab._onPartClicked(win, part, panel, x, y)
            return true
        end
    end
    for _, z in ipairs(win._healthInjuryZones or {}) do
        if x >= z.x and x <= z.x + z.w and y >= z.y and y <= z.y + z.h then
            ZeD.HealthTab._onPartClicked(win, z.bodyPartName, panel, x, y)
            return true
        end
    end
    return false
end

-- Health disclosure focusable: element[1] whether the figure is expanded or
-- collapsed (collapsed, the figure's parts are no stops). Reuses
-- _healthFigureZone, which HealthTab.render stamps per frame. Pattern mirrors
-- _buildThermalFocusables's disclosure element exactly.
local function _buildHealthDisclosureFocusable(win)
    local fz = win and win._healthFigureZone
    if not fz or (fz.w or 0) <= 0 then return {} end
    return {
        {
            x = fz.x, y = fz.y, w = fz.w, h = fz.h,
            id = "health:__disclosure",
            isDisclosure = true,
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on the chevron, mouse parity).
            onActivate = function(w, el)
                w._healthFigureExpanded = not w._healthFigureExpanded
            end,
        },
    }
end

-- Health tab main builder: concatenates the disclosure, body parts,
-- injuries and the footer band (exercise pop-up, - and +, Start last) into one
-- flat ring element list. Element order matters only for the initial seed
-- (cone-nav uses spatial bounds, not order). Disclosure first (the
-- disclosure-first rule every tab follows).
-- The open exercise list locks the stops to its rows; shutting it lands on the box.
local function _buildHealthFocusables(win)
    if not win then return {} end
    local band = _buildHealthBandFocusables(win)
    if band._menuRows then return band end
    local elements = _buildHealthDisclosureFocusable(win)
    local parts    = _buildHealthBodyPartFocusables(win)
    for i = 1, #parts do elements[#elements + 1] = parts[i] end
    local injuries = _buildHealthInjuryFocusables(win)
    for i = 1, #injuries do elements[#elements + 1] = injuries[i] end
    -- the fill blocks' heads and rows (ZeD_TabFill): a Regularity row picks that exercise
    -- for the band; the moodle, Fitness and strain rows only read
    local fill = ZeD.TabFill and ZeD.TabFill.focusables(win, "health", win._healthView) or {}
    for i = 1, #fill do elements[#elements + 1] = fill[i] end
    for i = 1, #band do
        elements[#elements + 1] = band[i]
        if win._healthReturnToMenu and band[i].id == "health:exercise" then
            elements._focusIdx = #elements
            win._healthReturnToMenu = nil
        end
    end
    return elements
end

-- Thermal tab focusables: the footer band's View pop-up box. A opens the list.
-- With it open the stops are its rows instead (the current
-- view first; A picks, B shuts it); shutting it returns the pad to the box. The band
-- is pinned, so the box is bandStop.
local function _buildThermalBandFocusables(win)
    local bz = win and win._thermalBand
    if not bz or not bz.box.w then return {} end
    local T = ZeD.ThermalTab
    local elements = {}
    if win._thermalMenuOpen and win._thermalMenuZones then
        local sel = win._thermalView or 1
        for i, z in ipairs(win._thermalMenuZones) do
            elements[#elements + 1] = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "thermal:viewRow:" .. tostring(z.id),
                menuRowId = z.id,
                onFocus = function(w, el) end,
                onActivate = function(w, el) T.closeMenu(w, el.menuRowId) end,
                onCancel = function(w, el) T.closeMenu(w) end,
            }
            if z.id == sel then elements._focusIdx = i end
        end
        elements._menuRows = true
        return elements
    end
    elements[1] = {
        x = bz.box.x, y = bz.box.y, w = bz.box.w, h = bz.box.h,
        id = "thermal:view", bandStop = true,
        onFocus = function(w, el) end,
        onActivate = function(w, el) T.openMenu(w) end,
    }
    return elements
end

-- Thermal tab focusables: body figure parts. Parts ARE focusable
-- because focus drives the right-column detail-view swap (mirror mouse
-- hover parity). A is a no-op — no action, only readout. Only populated
-- when the figure is expanded; collapsed figure yields empty list.
local function _thermalPartOnFocus(w, el)
    w._gpFocusedThermalPart = el.partName
end
local _thermalPartIds = {}   -- (each part's id, "thermalpart:<name>", made once)
local function _buildThermalBodyPartFocusables(win)
    if not win or not win._thermalFigureExpanded then return {} end
    local fig = win._thermalBodyFigure
    if not fig or not fig.getPartRects then return {} end
    local rects = fig:getPartRects()
    if not rects or #rects == 0 then return {} end
    -- (only the parts the body shows, clipped to it, as Health's: _inBodyView;
    -- Down from the lowest one shown reaches the grid or the band)
    local elements = {}
    local view = win._thermalBodyRect
    for i = 1, #rects do
        local r = rects[i]
        local vy, vh = _inBodyView(view, r.y, r.h)
        local id = vy and r.name and _thermalPartIds[r.name]
        if vy and not id then
            id = "thermalpart:" .. tostring(r.name)
            if r.name then _thermalPartIds[r.name] = id end
        end
        if vy then elements[#elements + 1] = {
            x = r.x, y = vy, w = r.w, h = vh, fullY = r.y, fullH = r.h,
            id = id,
            partName = r.name,
            onFocus = _thermalPartOnFocus,
            -- onActivate intentionally omitted — thermal parts are readout
            -- only; focus drives the detail-view swap, A does nothing.
        } end
    end
    if elements[1] and win._gpFocusedThermalPart == nil then
        win._gpFocusedThermalPart = elements[1].partName
    end
    return elements
end

-- Thermal grid scroll pseudo-focusable. Grid rows aren't focusable (stats
-- are readout, never stops), but the player needs a way to scroll the grid
-- with the D-pad. So: one pseudo-element covering the visible grid region;
-- D-pad up/down scrolls the thermal scroll (its onDpadDir), A does nothing.
-- Cone nav from body parts DOWN lands here.
local function _buildThermalGridScrollFocusable(win)
    local gz = win and win._thermalGridScrollZone
    if not gz or (gz.w or 0) <= 0 or (gz.h or 0) <= 0 then return {} end
    return {
        {
            x = gz.x, y = gz.y, w = gz.w, h = gz.h,
            id = "thermal:__gridscroll",
            isGridScroll = true,
            onFocus = function(w, el) end,
            -- onActivate omitted — A is a no-op here.
            -- D-pad U/D scrolls the grid; at limits, fall through to
            -- generic cone-nav so the player can leave upward to the body parts.
            onDpadDir = function(w, el, dir)
                local sc = w._thermalScroll
                if not sc then return false end
                local pos = sc.scrollPos or 0
                if dir == "down" and pos < 1 then
                    sc:setScrollPos(pos + 0.08); return
                elseif dir == "up" and pos > 0 then
                    sc:setScrollPos(pos - 0.08); return
                end
                return false  -- L/R always falls through; at-limit U/D too
            end,
        },
    }
end

-- Thermal tab aggregator. Disclosure FIRST so entering charTabContent
-- via LB/RB lands on the tab-header disclosure (tree-nav semantics — matches
-- the Equipment tab's disclosure being first in list mode). Then body parts, the
-- grid scroll pseudo-zone and the footer band's View pop-up. Cone-nav uses
-- spatial bounds, not order, so interleaving is safe for in-zone D-pad movement.
-- The open View list locks the stops to its rows; shutting it lands on the box.
local function _buildThermalFocusables(win)
    if not win then return {} end
    local band = _buildThermalBandFocusables(win)
    if band._menuRows then return band end
    local elements = {}
    -- Tab-header disclosure (A toggles _thermalFigureExpanded).
    local fz = win._thermalFigureZone
    if fz and (fz.w or 0) > 0 then
        elements[#elements + 1] = {
            x = fz.x, y = fz.y, w = fz.w, h = fz.h,
            id = "thermal:__disclosure",
            isDisclosure = true,
            -- No persistent state write — paint reads the live focused
            -- element via Focus.getFocusedElement(win).
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on the chevron, mouse parity).
            onActivate = function(w, el)
                w._thermalFigureExpanded = not w._thermalFigureExpanded
            end,
        }
    end
    local parts = _buildThermalBodyPartFocusables(win)
    for i = 1, #parts do elements[#elements + 1] = parts[i] end
    -- the grid's cells (A picks the region) and the picked region's rows (they read), ZeD_TabFill's
    -- stops; the old grid-scroll surface stays for a tab that stamps one
    local fill = ZeD.TabFill and ZeD.TabFill.focusables(win, "thermal", win._thermalBodyRect) or {}
    for i = 1, #fill do elements[#elements + 1] = fill[i] end
    local gridScroll = _buildThermalGridScrollFocusable(win)
    for i = 1, #gridScroll do elements[#elements + 1] = gridScroll[i] end
    -- the footer band's View pop-up last
    for i = 1, #band do
        elements[#elements + 1] = band[i]
        if win._thermalReturnToMenu and band[i].id == "thermal:view" then
            elements._focusIdx = #elements
            win._thermalReturnToMenu = nil
        end
    end
    return elements
end

-- Identity disclosure focusable. Element[1] in charTabContent on the
-- Identity tab. Tab header is the disclosure (full pattern parity with
-- Thermal/Health/Skills) — A toggles _identityPhotoExpanded,
-- which the ISUI3DModel avatar overlay reads to switch between bust crop
-- (collapsed) and full-body (expanded). Reads _identityFigureZone, which
-- IdentityTab.render stamps at the TOP each frame.
local function _buildIdentityDisclosureFocusable(win)
    local fz = win and win._identityFigureZone
    if not fz or (fz.w or 0) <= 0 then return {} end
    return {
        {
            x = fz.x, y = fz.y, w = fz.w, h = fz.h,
            id = "identity:__disclosure",
            isDisclosure = true,
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on the photo, mouse parity),
            -- and resets zoom and scroll as the click handlers do.
            onActivate = function(w, el)
                w._identityPhotoExpanded = not w._identityPhotoExpanded
                w._identityCustomZoom    = 0
                if w._identityScroll then w._identityScroll:setScrollPos(0) end
            end,
        },
    }
end

-- Identity grid-scroll pseudo-focusable: the fallback when the tab has no
-- stops of its own (ZeD.IdentityTab.focusables, see the aggregator below).
-- The whole visible content region becomes one scroll surface. D-pad up/down
-- (its onDpadDir) scrolls _identityScroll; at bounds, falls through to cone nav
-- which lands back on the disclosure above. A is a no-op. Only populated
-- when the content actually overflows (IdentityTab.render nils the zone
-- when needsScroll is false). Mirrors _buildThermalGridScrollFocusable.
local function _buildIdentityGridScrollFocusable(win)
    local gz = win and win._identityGridScrollZone
    if not gz or (gz.w or 0) <= 0 or (gz.h or 0) <= 0 then return {} end
    return {
        {
            x = gz.x, y = gz.y, w = gz.w, h = gz.h,
            id = "identity:__gridscroll",
            isGridScroll = true,
            onFocus = function(w, el) end,
            -- onActivate omitted — A is a no-op on grid scroll.
            -- D-pad U/D scrolls _identityScroll; at limits, fall through
            -- to cone-nav so the player can leave upward to the disclosure.
            onDpadDir = function(w, el, dir)
                local sc = w._identityScroll
                if not sc then return false end
                local pos = sc.scrollPos or 0
                if dir == "down" and pos < 1 then
                    sc:setScrollPos(pos + 0.08); return
                elseif dir == "up" and pos > 0 then
                    sc:setScrollPos(pos - 0.08); return
                end
                return false
            end,
        },
    }
end

-- Identity tab aggregator. Disclosure FIRST (the disclosure-first rule),
-- then the tab's own stops, or the grid-scroll pseudo-zone where it has none.
local function _buildIdentityFocusables(win)
    if not win then return {} end
    local elements = _buildIdentityDisclosureFocusable(win)
    -- the Hair and beard rows and each trait are stops (ZeD.IdentityTab.focusables);
    -- the tab scrolls to the focused one, so the grid-scroll surface is only the fallback
    local more = (ZeD.IdentityTab and ZeD.IdentityTab.focusables) and ZeD.IdentityTab.focusables(win)
        or _buildIdentityGridScrollFocusable(win)
    for i = 1, #more do elements[#elements + 1] = more[i] end
    return elements
end

-- ============================================================================
-- JOURNAL TAB FOCUSABLES
--
-- The Journal tab's five pages share one charTabContent zone. LB/RB lands on
-- charTabContent; D-pad handles everything inside. In order: the header's
-- Page pop-up (the box first, "jpage"; A opens its list,
-- whose rows alone hold the pad, "jpage:<n>"), then the page's body, then its band.
-- A page's own open list (Recipes' Category / Sort / Show, Papers' Show, Loadouts'
-- filter) holds the pad alone too.
-- ============================================================================

-- The header's stops: the Page box, or the Page list's rows (JournalTab owns them).
local function _buildJournalSubTabFocusables(win)
    local JT = ZeD.JournalTab
    if not (JT and JT.headerFocusables) then return {} end
    return JT.headerFocusables(win)
end

-- Journal page: the kills disclosure, a tab-row-like disclosure at the top
-- of the page. A toggles _killsExpanded (as a click on the kills row does).
local function _buildJournalKillsFocusable(win)
    local kz = win and win._journalKillsZone
    if not kz or (kz.w or 0) <= 0 then return {} end
    return {
        {
            x = kz.x, y = kz.y, w = kz.w, h = kz.h,
            id = "journal:__kills",
            isDisclosure = true,
            journalKind = "kills",
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on header, mouse parity).
            onActivate = function(w, el)
                w._killsExpanded = not w._killsExpanded
                w._journalCache = nil
            end,
        },
    }
end

-- Journal page: the Save button. A fires the existing save callback (the
-- button's onclick closure, made at window creation).
local function _buildJournalSaveFocusable(win)
    local sb = win and win._journalSaveBtnZone
    if not sb or (sb.w or 0) <= 0 then return {} end
    return {
        {
            x = sb.x, y = sb.y, w = sb.w, h = sb.h,
            id = "journal:__save",
            journalKind = "save",
            onFocus = function(w, el) end,
            onActivate = function(w, el)
                local btn = w._journalSaveBtn
                if btn and btn.onclick then
                    local ok, err = pcall(btn.onclick, btn.target, btn)
                    if not ok then
                        print("[ZeD] journal save onclick failed: " .. tostring(err))
                    end
                end
            end,
        },
    }
end

-- Journal page: month-group header focusables. Each group header is a
-- disclosure — A toggles _journalGroupCollapsed[key] (as a click does).
local function _buildJournalGroupFocusables(win)
    local zones = win and win._journalGroupZones
    if not zones or #zones == 0 then return {} end
    local elements = {}
    for _, z in ipairs(zones) do
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = "journal:group:" .. tostring(z.id),
            isDisclosure = true,
            journalKind = "group",
            groupKey = z.id,
            onFocus = function(w, el) end,
            -- A toggles expand/collapse (= LMB on header, mouse parity).
            onActivate = function(w, el)
                w._journalGroupCollapsed = w._journalGroupCollapsed or {}
                w._journalGroupCollapsed[el.groupKey] = not w._journalGroupCollapsed[el.groupKey]
                w._journalCache = nil
            end,
        }
    end
    return elements
end

-- Journal page: per-entry delete button focusables. A asks first where the
-- tab has a question band (askJournalDelete), else removes the entry from
-- modData, as a click does. Only the entries near the log's view (inPadReach).
local function _buildJournalDeleteFocusables(win)
    local zones = win and win._journalDeleteZones
    if not zones or #zones == 0 then return {} end
    local elements = {}
    local JT = ZeD.JournalTab
    for _, z in ipairs(zones) do
      if not (JT and JT.inPadReach) or JT.inPadReach(win, z) then
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h,
            id = "journal:del:" .. tostring(z.entryIdx),
            journalKind = "delete",
            entryIdx = z.entryIdx,
            onFocus = function(w, el) end,
            onActivate = function(w, el)
                -- the entry is asked about first (the Journal tab's question band), when the tab has one
                if askJournalDelete(w, el.entryIdx) then return end
                local md = w._playerObj and w._playerObj:getModData()
                if md and md.ZeD_Journal and md.ZeD_Journal.entries then
                    table.remove(md.ZeD_Journal.entries, el.entryIdx)
                end
                w._journalCache = nil
            end,
        }
      end
    end
    return elements
end

-- Journal page content aggregator: the kills disclosure, the tag picks under
-- the write box, the month group headers, each entry's tags and delete cross
-- (in its head row, right of the date: the D-pad walks them left and right),
-- then Save in the page's band. X on any of them clears the search. Text entry
-- stays mouse-only (no text input is a stop).
local function _buildJournalSubContent(win)
    if not win then return {} end
    -- a question is up (delete an entry?): its two answers are the only stops (Cancel first; B cancels)
    local JT = ZeD.JournalTab
    if win._journalAsk and JT and JT.askFocusables then return JT.askFocusables(win) end
    local elements = _buildJournalKillsFocusable(win)
    local tags = JT and JT.tagFocusables and JT.tagFocusables(win) or {}
    for i = 1, #tags do elements[#elements + 1] = tags[i] end
    local groups = _buildJournalGroupFocusables(win)
    for i = 1, #groups do elements[#elements + 1] = groups[i] end
    local dels = _buildJournalDeleteFocusables(win)
    for i = 1, #dels do elements[#elements + 1] = dels[i] end
    -- Save, in the page's band
    local save = _buildJournalSaveFocusable(win)
    if save[1] then elements[#elements + 1] = save[1] end
    if JT and JT.withClear then JT.withClear(elements) end
    return elements
end

-- Journal Recipes page focusables. Thin wrapper over the shared
-- CC.buildFocusables helper (CraftingCore.lua) with readOnly config:
-- no pin (no pinKey), no startAction. CraftingCore still tags the
-- jrecipe-prefixed elements with a `journalKind` field; nothing reads it.
local function _buildJournalRecipesFocusables(win)
    return ZeD.CraftingCore.buildFocusables(win, win and win._jrecipeState,
        "jrecipe", nil, nil)
end

-- Journal tab aggregator. The header's stops first (the Page box), then the
-- open page's own. An open Page list, a page's own open list or a question
-- holds the pad alone (below).
local function _buildJournalFocusables(win)
    if not win then return {} end
    -- while the Journal asks before deleting an entry, its answers alone hold the
    -- controller (the Page box comes back when it is answered)
    if win._journalAsk and (win._journalSubTab or 1) == 1 then return _buildJournalSubContent(win) end
    -- the Page list open: its rows alone
    local JT = ZeD.JournalTab
    if JT and JT.pageMenuOpen and JT.pageMenuOpen(win) then return _buildJournalSubTabFocusables(win) end
    local listOpen = JT and JT.pageListOpen and JT.pageListOpen(win)
    local elements = listOpen and {} or _buildJournalSubTabFocusables(win)
    local sub = win._journalSubTab or 1
    local subEls = {}
    if sub == 1 then
        subEls = _buildJournalSubContent(win)
    elseif sub == 2 or sub == 3 then
        -- Notebooks, Papers (ZeD_JournalReaders stamps its own zones)
        subEls = ZeD.JournalReaders and ZeD.JournalReaders.focusables(win) or {}
    elseif sub == 4 then
        subEls = _buildJournalRecipesFocusables(win)
    elseif sub == 5 then
        -- Loadouts (ZeD_JournalLists stamps its own zones); its question band holds the pad alone
        subEls = ZeD.JournalLists and ZeD.JournalLists.focusables(win) or {}
        if ZeD.JournalLists and ZeD.JournalLists.state(win).ask then return subEls end
    end
    for i = 1, #subEls do elements[#elements + 1] = subEls[i] end
    -- a page's own pop-up list open: its rows alone, modal
    if listOpen and subEls._menuRows then elements._menuRows = true end
    -- where the page asks the focus to land (an element of the page's, after the Page box;
    -- back from the Page list the box keeps it)
    if subEls._focusIdx and not elements._focusIdx then elements._focusIdx = #elements - #subEls + subEls._focusIdx end
    return elements
end

-- Build per-tab DRAWER focusables. In the ring model, charTabContent holds
-- the tab's own stops (equipment slots, the health band, the thermal View
-- box, skill rows). The MAIN inventory list lives in its own
-- zone (charMainInv), always present regardless of tab. Loot tab has no
-- separate drawer content, so this returns {} for loot — LB/RB skip it and
-- go straight to charMainInv which holds the invrows.
_buildPanelFocusables = function(win, content, tabId)
    if not win then return {} end
    -- Loot: no tab drawer, invrows live in charMainInv.
    if tabId == "loot"     then return {}                              end
    if tabId == "skills"   then return _buildSkillsFocusables(win)     end
    if tabId == "equip"    then return _buildEquipmentFocusables(win)  end
    if tabId == "health"   then return _buildHealthFocusables(win)     end
    if tabId == "thermal"  then return _buildThermalFocusables(win)    end
    if tabId == "identity" then return _buildIdentityFocusables(win)   end
    if tabId == "journal"  then return _buildJournalFocusables(win)    end
    -- Radio's focusable builder lives in RadioTab.lua, not a file-local.
    -- Guarded the same way as the World window's `maps` branch.
    if tabId == "radio" then
        if ZeD and ZeD.RadioTab and ZeD.RadioTab.buildFocusables then
            return ZeD.RadioTab.buildFocusables(win)
        end
        return {}
    end
    return ZeD_CharacterWindow.extFocusables(win, tabId)
end

-- Find the index of the currently-active tab in a freshly-built tabEls
-- array. Used to seed `focusedElementIdx` on the charTabBar zone so the ring
-- starts on the visually-active tab instead of always idx 1.
local function _findActiveTabIdx(tabEls, tabId)
    for i, el in ipairs(tabEls) do
        if el.tabId == tabId then return i end
    end
    return 1
end

-- An open list shuts only on a pick, B, a click outside it, or leaving the tab;
-- never on a hitch or with time passing. This shuts every pop-up list of the
-- window's tabs but keepTab's (nil: all), through its owner, so its rows and zones
-- go with it and the focus lands on its box. Called on a tab change
-- (_clearGpFocusState) and each frame (the drawer folded, an item card over it,
-- the tab gone: keepTab nil).
local function _shutTabLists(w, keepTab)
    if w._healthMenuOpen and keepTab ~= "health" and ZeD.HealthTab then ZeD.HealthTab.closeMenu(w) end
    if w._thermalMenuOpen and keepTab ~= "thermal" and ZeD.ThermalTab then ZeD.ThermalTab.closeMenu(w) end
    local JT = ZeD.JournalTab
    if keepTab ~= "journal" and JT and JT.listsOpen and JT.listsOpen(w) then JT.shutLists(w) end
end

-- Clear all _gpFocused* chrome state fields on the window + content.
-- Called from _syncRingZonesToActiveTab (every tab switch and ring re-sync)
-- so a new tab paints with a clean focus cursor. (There is no focus stack to
-- pop: clearing this state is all a switch needs.)
_clearGpFocusState = function(w)
    if not w then return end
    w._gpFocusedRowItem      = nil
    w._gpFocusedSkill        = nil
    w._gpFocusedInjury       = nil
    w._gpFocusedBodyPart     = nil
    w._gpFocusedThermalPart  = nil
    -- the pop-up lists are shut with the tab, through their owners; the focus
    -- goes to the new tab, not back to a list's box
    _shutTabLists(w, nil)
    w._healthReturnToMenu    = nil
    w._thermalReturnToMenu   = nil
    w._gpFocusedEquipSlot    = nil
    w._gpFocusedRadioCtl     = nil  -- the radio drawer's focused chassis control id
    w._healthActivePart      = nil  -- Health's resolved part (pad focus over mouse hover)
    -- Clear the journal scroll-follow delta-gate pin so the next visit
    -- re-pins on first focus instead of inheriting the previous element's
    -- position as "already correct".
    w._lastPinnedJournalId   = nil
    -- Clear the CC scroll-follow delta-gate pins (one per CC-driven prefix).
    -- Same rationale as journal — fresh tab visit must re-pin on first focus.
    w._lastPinnedRecipeId_jrecipe = nil
    w._lastPinnedRecipeId_craft   = nil
    w._lastPinnedRecipeId_build   = nil
    -- Clear the MC zone focus + delta-gate pin on tab-switch / mode reset.
    w._gpFocusedMCItem       = nil
    w._gpFocusedMCColIdx     = nil
    w._lastPinnedMCItem      = nil
    w._invRowsForContainer   = nil
    local c = w._mainContent
    if c then c._gpFocusedRowItem = nil end
end

-- Wire up callbacks on a fresh tabBar element list. Called right before
-- claimFocus in the window's open path — the closure captures `win` so
-- callbacks resolve `win._mainContent` at fire time (content may not exist
-- yet when this runs, but will by the time any user input arrives).
local function _attachTabBarCallbacks(win, tabElements)
    for _, el in ipairs(tabElements) do
        -- An A press switches tabs; D-pad focus on a tab does not, so the
        -- player can run the D-pad through the tabs without committing, then
        -- press A to activate. Mouse parity (LMB on tab = switch).
        -- onFocus left as a no-op so the focus cue still tracks the highlighted
        -- tab; the active-tab visual remains anchored to _activeTab so players
        -- can see "I'm hovering tab X but tab Y is still active."
        el.onFocus = function(w, e) end
        el.onActivate = function(w, e)
            local c = w._mainContent
            if c then _switchTabForNav(w, c, e.tabId) end
        end
    end
end

-- ============================================================================
-- TAB STRIP DRAW — _onPrerender hook for the strip ZeD_Panel
-- ============================================================================

-- Measure total tab strip content height. Takes win so contextual tabs
-- (e.g. radio) that fail their visibility predicate don't allocate strip space.
local function measureTabStripH(win)
    local T = ZeD.T
    local totalH = 0
    local lastGroup = 1
    for _, tab in ipairs(CHAR_TABS) do
        if isTabVisible(tab, win) then
            if tab.group ~= lastGroup then
                totalH = totalH + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            totalH = totalH + T.stripH
        end
    end
    return totalH
end

local TAB_ARROW_ROW_H = 16  -- height of the bottom [^ v] scroll row

-- The strip, when it scrolls, brings the tab that matters into view: the controller's focused
-- tab, else the active one. Only when that tab changes (a new focus, a new active tab, the
-- strip just starting to scroll), so the wheel and the arrows can still look elsewhere.
-- (At 1280x720, UI scale 2.0 and Large text the strip scrolls; without this a controller
-- moving down past Identity focused Journal, Skills and Radio out of sight.)
local function tabStripFollow(win, viewH, scrollOff, maxScroll, focusedId)
    local tgt = focusedId or win._activeTab
    local isPad = focusedId ~= nil
    if tgt == win._tabFollowId and isPad == win._tabFollowPad then return scrollOff end
    win._tabFollowId, win._tabFollowPad = tgt, isPad
    local T = ZeD.T
    local y, lastGroup, btn = 0, 1, T.stripH
    for _, tab in ipairs(CHAR_TABS) do
        if isTabVisible(tab, win) then
            if tab.group ~= lastGroup then
                y = y + T.px(TAB_SEP_MAR) + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
                lastGroup = tab.group
            end
            if tab.id == tgt then
                if y < scrollOff then scrollOff = y
                elseif y + btn > scrollOff + viewH then scrollOff = y + btn - viewH end
                return math.max(0, math.min(scrollOff, maxScroll))
            end
            y = y + btn
        end
    end
    return scrollOff
end

local function drawTabStrip(self, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local w  = T.px(TAB_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()

    -- Strip background provided by ZeD_Window body — no redundant fill

    -- The waterfall's inner edge: a structure line
    local bd = T.borderS
    self:drawRect(w - T.px(1), 0, T.px(1), h, bd.a, bd.r, bd.g, bd.b)

    -- Glyph metrics
    local font   = T.fontF1
    local fontH  = ZeD.TM:getFontHeight(font)
    local mx, my = self:getMouseX(), self:getMouseY()

    -- Check if tabs overflow (visible tabs only)
    local totalTabH = measureTabStripH(win)
    local scrollOff = win._tabScrollOffset or 0

    -- If the active tab is no longer visible (e.g. the Radio tab was open
    -- when the last radio went), fall back to "loot" so the drawer
    -- has something to render and the strip doesn't paint a phantom active.
    do
        local activeStillVisible = false
        for _, t in ipairs(CHAR_TABS) do
            if t.id == win._activeTab and isTabVisible(t, win) then
                activeStillVisible = true; break
            end
        end
        if not activeStillVisible then
            -- (back to Loot with the drawer shut, as pressing Loot does. Setting only the tab left the drawer
            -- open in tab mode, and it drew the "placeholder" card for "loot". An item card over the vanished
            -- tab stays: only a tab drawer is shut.)
            if win._drawerMode == "tab" and win._mainContent then
                _switchTabForNav(win, win._mainContent, "loot")
            else
                win._activeTab = "loot"
            end
        end
    end
    -- The controller's focus on the strip, resolved once: only while this window
    -- has the focus and the controller is in use (Focus.liveZone), so the mark
    -- never lingers in the other window or under the mouse. The active tab shows
    -- it too (the mark on a solid element leaves out its wash). (Resolved before
    -- the scroll: a focused tab out of sight scrolls into view.)
    local gpFocusedTabId = nil
    local cuesOn = false
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local zone = Focus and Focus.liveZone and Focus.liveZone(win)
        if zone and zone.zone == "charTabBar" then
            local el = Focus.liveElement(win)
            if el then gpFocusedTabId = el.tabId end
        end
        cuesOn = Focus and Focus.cuesVisible and Focus.cuesVisible(win.playerNum) or false   -- (this window's player's marks)
    end

    local needsScroll = totalTabH > h
    local arrowRowH = 0

    if needsScroll then
        arrowRowH = T.px(TAB_ARROW_ROW_H)
        -- Clamp scroll offset
        local maxScroll = totalTabH - (h - arrowRowH)
        if maxScroll < 0 then maxScroll = 0 end
        scrollOff = math.max(0, math.min(scrollOff, maxScroll))
        scrollOff = tabStripFollow(win, h - arrowRowH, scrollOff, maxScroll, gpFocusedTabId)
        win._tabScrollOffset = scrollOff

        local canScrollUp   = scrollOff > 0
        local canScrollDown = scrollOff < maxScroll

        -- Bottom arrow row: [^ v] side by side
        local rowY = h - arrowRowH
        -- Divider above arrow row
        local sep = T.borderS
        self:drawRect(0, rowY, w - T.px(1), T.px(1), sep.a, sep.r, sep.g, sep.b)

        local halfW = math.floor(w / 2)

        -- Up button (left half)
        local hoverUp = canScrollUp and (mx >= 0 and mx < halfW and my >= rowY and my < h)
        if hoverUp then
            local s2 = T.hover   -- (the hover wash)
            self:drawRect(0, rowY + T.px(1), halfW, arrowRowH - T.px(1), s2.a, s2.r, s2.g, s2.b)
        end
        local upC = canScrollUp and (hoverUp and T.text or T.textDim) or T.border
        A.drawTriangleUp(self, math.floor((halfW - T.px(ARROW_SZ)) / 2), rowY + math.floor((arrowRowH - T.px(ARROW_SZ)) / 2), T.px(ARROW_SZ), upC)
        if canScrollUp then
            self:addHitZone("tab_scroll_up", 0, rowY, halfW, arrowRowH)
        end

        -- Down button (right half)
        local hoverDn = canScrollDown and (mx >= halfW and mx < w and my >= rowY and my < h)
        if hoverDn then
            local s2 = T.hover   -- (the hover wash)
            self:drawRect(halfW, rowY + T.px(1), halfW, arrowRowH - T.px(1), s2.a, s2.r, s2.g, s2.b)
        end
        local dnC = canScrollDown and (hoverDn and T.text or T.textDim) or T.border
        A.drawTriangleDown(self, halfW + math.floor((halfW - T.px(ARROW_SZ)) / 2), rowY + math.floor((arrowRowH - T.px(ARROW_SZ)) / 2), T.px(ARROW_SZ), dnC)
        if canScrollDown then
            self:addHitZone("tab_scroll_down", halfW, rowY, halfW, arrowRowH)
        end
    else
        win._tabScrollOffset = 0
        win._tabFollowId = nil   -- the next time the strip scrolls, it brings the active tab into view
    end

    -- Stencil for tab content area (above arrow row)
    local tabAreaH = h - arrowRowH
    self:setStencilRect(0, 0, w, tabAreaH)

    local tabFocusOpts = { win = win, zone = "charTabBar" }
    local tabDrawOpts = {}

    local curY      = -scrollOff
    local lastGroup = 1

    for _, tab in ipairs(CHAR_TABS) do
        -- Skip contextual tabs that fail their visibility predicate.
        -- Group separator suppressed too — it'll fire on the next visible tab
        -- if that tab is in a different group than the last drawn one.
        if not isTabVisible(tab, win) then
            -- intentionally skipped
        else
        -- Group separator
        if tab.group ~= lastGroup then
            curY = curY + T.px(TAB_SEP_MAR)
            local sep = T.borderS
            self:drawRect(T.px(4), curY, w - T.px(8), T.px(TAB_SEP_H), sep.a, sep.r, sep.g, sep.b)
            curY = curY + T.px(TAB_SEP_H) + T.px(TAB_SEP_MAR)
            lastGroup = tab.group
        end

        local isActive = (tab.id == win._activeTab)
        local isHover  = (mx >= 0 and mx < w and my >= curY and my < curY + T.stripH)

        -- The tabs are lit pixel art (ZeD_TabPx): the
        -- active tab a bevelled lit accent panel with its icon pressed in, every
        -- icon a small lit object in five tones of the accent. The pointer's
        -- hover is the T.hover wash; the controller's focus is the player's
        -- focus mark, on the active tab too. Every tab id has a lit icon.
        local TPX = ZeD.TabPx
        if TPX and TPX.has(tab.id) then
            tabDrawOpts.focus = (gpFocusedTabId == tab.id) and tabFocusOpts or nil
            tabDrawOpts.help = isHover and ZeD.tr("UI_ZeD_CW_TabHelp", ZeD_CharacterWindow.tabLabel(tab)) or nil
            TPX.drawTab(self, 0, curY, w - T.px(1), T.stripH - T.px(1), tab.id, isActive,
                isHover and not cuesOn and not isActive, T.px(1), tabDrawOpts)
        end

        -- Bottom border between tabs
        local bd = T.border
        self:drawRect(0, curY + T.stripH - T.px(1), w, T.px(1), bd.a, bd.r, bd.g, bd.b)

        -- Hit zone — always active, clicking exits mc mode if needed
        if curY + T.stripH > 0 and curY < tabAreaH then
            self:addHitZone("tab:" .. tab.id, 0, curY, w, T.stripH)
            -- the tab's name in a balloon beside it: after the pause for the mouse, at once for the
            -- controller's focus
            if isHover and my < tabAreaH and (not self.isMouseOver or self:isMouseOver()) then
                win._tabHintCand = { key = "tab:" .. tab.id, text = ZeD_CharacterWindow.tabLabel(tab),
                                     x = self:getX(), y = self:getY() + curY, w = w, h = T.stripH, side = "r" }
                ZeD.Atoms.syncHintLayer(win, win._tabHintLayer)
            elseif cuesOn and gpFocusedTabId == tab.id and not win._tabHintCand then
                win._tabHintCand = { key = "tab:" .. tab.id, text = ZeD_CharacterWindow.tabLabel(tab),
                                     x = self:getX(), y = self:getY() + curY, w = w, h = T.stripH, side = "r", now = true }
                ZeD.Atoms.syncHintLayer(win, win._tabHintLayer)
            end
        end

        curY = curY + T.stripH
        end -- close visibility-skip if/else
    end

    self:clearStencilRect()
end

-- ============================================================================
-- CONTAINER ENUMERATION
-- ============================================================================

--- A general hook for other mods (ExtraContainers.lua): fn(playerObj, list)
--- returns more containers for the strip ({ container = ItemContainer, item,
--- parentItem, name, texture }); each gets a button and a column like a worn
--- bag. A second call with the same id replaces the first.
function ZeD_CharacterWindow.addContainerProvider(id, fn)
    ZeD.ExtraContainers.add("char", id, fn)
end

--- A general hook for other mods (StripDecorators.lua): fn(panel, entry, x, y,
--- w, h, win) is called after each strip button's icon is drawn (the main
--- inventory's too), with the window's entry (entry.inventory) and the button's
--- rectangle, to mark it (a fill bar, a badge). A second call with the same id
--- replaces the first.
function ZeD_CharacterWindow.addStripDecorator(id, fn)
    ZeD.StripDecorators.add("char", id, fn)
end

local function buildContainers(playerObj)
    local containers = {}
    local mainInv = playerObj:getInventory()
    containers[#containers + 1] = {
        inventory = mainInv,
        name = getText("IGUI_InventoryTooltip"),
        texture = getTexture("media/ui/Container_Pocket.png"),
        isMain = true,
    }
    local items = mainInv:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if (item:getCategory() == "Container" and playerObj:isEquipped(item))
           or item:isItemType(ItemType.KEY_RING)
           or item:hasTag(ItemTag.KEY_RING) then
            containers[#containers + 1] = {
                inventory = item:getInventory(),
                name = item:getName(),
                texture = item:getTex(),
                isMain = false,
            }
        end
    end
    -- other mods' containers (ExtraContainers.lua): each one placed after the
    -- bag it is carried in; the main inventory stays first
    return ZeD.ExtraContainers.merge("char", playerObj, containers)
end


-- ============================================================================
-- CONTAINER STRIP DRAW — the vertical strip on the window's right edge
-- Main inventory pinned top, the sort toggle, draggable bag list, scroll arrows
-- ============================================================================

local STRIP_SCROLL_ROW_H = 16  -- height of the bottom [^ v] scroll row

-- Installs a freshly built bag list and keeps every choice on the same bag it
-- was on, matched by its inventory rather than its place in the list (by
-- place, taking off a bag listed before another one would switch the pane to
-- the other bag). A viewed bag that is gone falls back to the main inventory;
-- an active bag that is gone falls back to the main inventory and drops its
-- selection; a multi-column bag that is gone loses its column.
local function remapCharContainers(win, content, oldList, newList)
    local function find(oldIdx)
        local old = oldList and oldIdx and oldList[oldIdx]
        if not old then return nil end
        for i, c in ipairs(newList) do
            if c.inventory == old.inventory then return i end
        end
        return nil
    end
    win._containers = newList

    local active = find(win._activeContainer)
    if active then
        win._activeContainer = active
    else
        win._activeContainer = 1
        content._inventory = newList[1].inventory
        content._selectedItems = {}
        content._lastClickedItem = nil
    end
    if win._viewedContainer then win._viewedContainer = find(win._viewedContainer) end

    local mcOld = win._mcSelected
    if mcOld and #mcOld > 0 then
        local mcNew, moved = {}, false
        for _, oldIdx in ipairs(mcOld) do
            local i = find(oldIdx)
            if i then mcNew[#mcNew + 1] = i end
            if i ~= oldIdx then moved = true end
        end
        win._mcSelected = mcNew
        -- Any column whose bag went away or changed place needs its column
        -- state rebuilt; a bag that only shifted keeps its own scroll and
        -- selection because its state is re-pointed at the new place first.
        if moved then
            if #mcNew == 0 then
                exitMultiContainer(win, content)
            else
                for _, cs in ipairs(content._colStates or {}) do
                    local newIdx = nil
                    for i, c in ipairs(newList) do
                        if c.inventory == cs.inventory then newIdx = i; break end
                    end
                    cs.containerIdx = newIdx
                end
                local colSel = {}
                for _, ci in ipairs(mcNew) do colSel[#colSel + 1] = ci end
                if win._mainVisible then colSel[#colSel + 1] = 1 end
                content._selectedContainers = colSel
                content._containers = newList
                getR().rebuildColStates(content)
                if #mcNew ~= #mcOld or (content._activeCol or 1) > #colSel then
                    content._activeCol = #colSel
                end
            end
            win._invDrawerTargetW = computeInvDrawerTarget(win)
            if _syncRingZonesToActiveTab then _syncRingZonesToActiveTab(win, content) end
        end
    end
end

-- Sorts the strip's display order in place: "wt" heaviest first, "type" by
-- name, "dist" leaves the natural (or hand-dragged) order. The main inventory
-- stays first. Each bag's weight is read once per sort, not once per compare.
local function sortContainerOrder(containers, order, sortMode)
    if sortMode == "wt" then
        local wt = {}
        for _, ci in ipairs(order) do
            local inv = containers[ci] and containers[ci].inventory
            wt[ci] = inv and inv:getCapacityWeight() or 0
        end
        table.sort(order, function(a, b)
            if containers[a].isMain then return true end
            if containers[b].isMain then return false end
            return wt[a] > wt[b]
        end)
    elseif sortMode == "type" then
        table.sort(order, function(a, b)
            if containers[a].isMain then return true end
            if containers[b].isMain then return false end
            return (containers[a].name or "") < (containers[b].name or "")
        end)
    end
end

local function drawContainerStrip(self, win, content)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local w  = T.px(CONTAINER_STRIP_W)
    local h  = self:getHeight()

    self:clearHitZones()

    -- The controller's focus on the strip: the button the ring focuses in this
    -- zone, only while this window has the focus and the controller is in use
    -- (Focus.liveZone), so nothing stays lit in the other window or under the
    -- mouse. Its mark shows on a selected bag too (selected is a 0.30 wash).
    local gpFocusedCI = nil
    local cuesOn = false
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        local zone = Focus and Focus.liveZone and Focus.liveZone(win)
        if zone and zone.zone == "charContainerStrip" then
            local el = Focus.liveElement(win)
            if el then gpFocusedCI = el.containerIdx end
        end
        cuesOn = Focus and Focus.cuesVisible and Focus.cuesVisible(win.playerNum) or false   -- (this window's player's marks)
    end
    local stripFocus = { win = win, zone = "charContainerStrip" }
    local selA = T.selectionA or 0.30

    -- Periodic container refresh. The active, viewed and multi-column bags follow their bag, not their place in the
    -- list. Every 500 ms by the clock (a frame count of 30 would run it 2.4 times as often at
    -- 144 Hz as at 60 fps). win._containerTimer is the signal: 30 set by others refreshes on
    -- the next frame, 0 marks the frame the list was rebuilt (the sort below reads it).
    local nowMs = getTimestampMs()
    if (win._containerTimer or 0) < 30 and nowMs < (win._containerDueMs or 0) then
        win._containerTimer = 1
    else
        win._containerTimer = 0
        win._containerDueMs = nowMs + 500
        remapCharContainers(win, content, win._containers, buildContainers(win._playerObj))

        -- Refresh equipped radios + clamp browse index. Wave cache
        -- prunes against the new key set (entry.cacheKey is the equipped slot
        -- tag — Primary/Secondary/Back — set in RadioTab.buildEquippedRadios).
        win._radios = ZeD.RadioTab.buildEquippedRadios(win._playerObj)
        if #win._radios == 0 then
            win._radioIdx = 1
        elseif win._radioIdx > #win._radios then
            win._radioIdx = #win._radios
        end
        if win._radioWaveCache then
            local stillPresent = {}
            for _, entry in ipairs(win._radios) do
                if entry.cacheKey then stillPresent[entry.cacheKey] = true end
            end
            for k in pairs(win._radioWaveCache) do
                if not stillPresent[k] then win._radioWaveCache[k] = nil end
            end
        end
    end

    -- Build display order
    local containers = win._containers
    local order = win._containerOrder
    if not order or #order ~= #containers then
        order = {}
        for i = 1, #containers do order[i] = i end
        win._containerOrder = order
    end
    local sortMode = win._containerSortMode or "dist"
    -- Re-sort only when the list just refreshed (every 30 frames, above), the
    -- order was rebuilt or the sort mode changed, not every frame
    if win._containerTimer == 0 or win._sortedOrder ~= order or win._sortedMode ~= sortMode then
        win._sortedOrder, win._sortedMode = order, sortMode
        sortContainerOrder(containers, order, sortMode)
    end

    -- Strip background provided by ZeD_Window body — no redundant fill
    -- The strip's inner edge: a structure line; the lines between buttons are content lines
    local bs = T.borderS
    self:drawRect(0, 0, T.px(1), h, bs.a, bs.r, bs.g, bs.b)
    local bd = T.border

    local mx, my = self:getMouseX(), self:getMouseY()
    local font   = T.fontF1
    local fontH  = ZeD.TM:getFontHeight(font)
    local iconSz = T.px(CONTAINER_BTN_SZ - 14)  -- 22px icon in 36px cell (design units)

    -- --------------------------------------------------------
    -- ZONE 1: Main (on-person) container permanently pinned at top.
    -- Showing whichever container was active here made containers "shuffle
    -- to the top" on activation — disruptive for gamepad nav (element
    -- y-coords shifted underneath the focused cursor) and confusing for the
    -- mouse. So main is always Zone 1; the others live in Zone 3 in a
    -- stable display order.
    -- --------------------------------------------------------
    local mainCnt = containers[1]  -- buildContainers guarantees main at index 1
    local curY = 0
    -- the main cell and the line under it are row 1 (T.stripH), level with the tab's header
    local mainH = T.stripH - T.px(1)
    if mainCnt then
        local isHover = (mx >= 0 and mx < w and my >= curY and my < curY + mainH) and not cuesOn
        -- Zone 1 is "on" when: main visible (loot MC), or inventory open showing main (non-loot)
        local mainVis
        if win._activeTab == "loot" then
            -- (lit means listed: a bag's view over main lights the bag alone)
            mainVis = win._mainVisible and (win._viewedContainer == nil or win._viewedContainer == 1)
        else
            mainVis = win._invDrawerOpen and (win._viewedContainer == nil)
        end
        -- the one selected look (the shown bag), the hover wash, then the controller's mark
        if mainVis then
            local ac = T.accent
            self:drawRect(T.px(1), curY, w - T.px(1), mainH, selA, ac.r, ac.g, ac.b)
        elseif isHover then
            local hv = T.hover
            self:drawRect(T.px(1), curY, w - T.px(1), mainH, hv.a, hv.r, hv.g, hv.b)
        end
        if isHover then ZeD.Help.set(self, ZeD.tr("UI_ZeD_CW_MainHelp", mainCnt.name or "")) end
        local onFocusM = false
        if gpFocusedCI == 1 then
            onFocusM = ZeD.Focus.mark(self, T.px(1), curY, w - T.px(1), mainH, stripFocus)
        end
        local iconAlpha = mainVis and 1 or 0.5
        local tex = mainCnt.texture or (ZeD.genericContainerTex and ZeD.genericContainerTex())
        if tex then
            local ix = math.floor((w - iconSz) / 2)
            local iy = curY + math.floor((mainH - iconSz) / 2)
            self:drawTextureScaledAspect(tex, ix, iy, iconSz, iconSz, iconAlpha, 1, 1, 1)
        else
            local glyph = "I"
            local gw = ZeD.TM:MeasureStringX(font, glyph)
            local gx = math.floor((w - gw) / 2)
            local gy = curY + math.floor((mainH - fontH) / 2)
            local color = onFocusM and T.textOnFocus or (mainVis and T.text or T.textDim)
            self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
        end
        -- other mods' marks on the button (StripDecorators.lua); before the badge below so the badge stays on top
        ZeD.StripDecorators.run(self, win, "char", mainCnt, T.px(1), curY, w - T.px(1), mainH)
        -- MC badge for main (player inv) when MC active. Main is
        -- always at the last colSel position when mainVisible=true, so its
        -- badge = #_mcSelected + 1.
        local mcCountM = #(win._mcSelected or {})
        if mainVis and mcCountM > 0 then
            local badge = tostring(mcCountM + 1)
            local bx = T.px(4)
            local by = curY + mainH - fontH - T.px(1)
            local bc = onFocusM and T.textOnFocus or T.text
            self:drawText(badge, bx, by, bc.r, bc.g, bc.b, bc.a, font)
        end
        -- Hit zone: clickable on all tabs
        self:addHitZone("main_toggle", 0, curY, w, mainH)
        curY = curY + mainH
    end

    -- Divider below the main container
    A.drawDividerH(self, 0, curY, w, true)
    curY = curY + T.px(1)

    -- --------------------------------------------------------
    -- ZONE 2: Sort mode label — aligned with column header bar Y
    -- Cycles: dist → wt → type → dist
    -- --------------------------------------------------------
    -- row 2, the sort bar (T.sortBarH), its word in the sort font: level with the inventory's column header
    local colHdrH   = T.sortBarH
    local sortRowY  = curY
    local sortRowH  = colHdrH
    local f5Font    = T.sortFont
    local f5H       = ZeD.TM:getFontHeight(f5Font)
    local isActive  = sortMode ~= "dist"
    -- sortMode stays "dist" / "wt" / "type" (it is the saved choice and the cycle's key); the label is its word
    local sortLabel = ZeD.tr((sortMode == "wt" and "UI_ZeD_Char_SortWt") or (sortMode == "type" and "UI_ZeD_Char_SortType") or "UI_ZeD_Char_SortDist")
    local labelW    = ZeD.TM:MeasureStringX(f5Font, sortLabel)
    local isSortHover = (mx >= 0 and mx < w and my >= sortRowY and my < sortRowY + sortRowH) and not cuesOn

    -- the header row's surface (one layer over the body); an order other than
    -- distance shows as its underlined word, the pointer as the hover wash
    ZeD.Surface.fill(self, T.px(1), sortRowY, w - T.px(1), sortRowH, "surf2")
    if isSortHover then
        local hv = T.hover
        self:drawRect(T.px(1), sortRowY, w - T.px(1), sortRowH, hv.a, hv.r, hv.g, hv.b)
        ZeD.Help.set(self, ZeD.tr("UI_ZeD_CW_SortHelp"))
    end
    local sortColor = isActive and T.toneNorm or T.toneLo
    local labelX = math.floor((w - labelW) / 2)
    local labelY = sortRowY + math.floor((sortRowH - f5H) / 2)
    self:drawText(sortLabel, labelX, labelY, sortColor.r, sortColor.g, sortColor.b, sortColor.a, f5Font)
    -- Underline when active sort
    if isActive then
        self:drawRect(labelX, labelY + f5H, labelW, T.px(1), sortColor.a, sortColor.r, sortColor.g, sortColor.b)
    end
    self:addHitZone("wt_sort", 0, sortRowY, w, sortRowH)
    curY = sortRowY + sortRowH

    -- Divider lines matching content panel's column header
    A.drawDividerH(self, 0, sortRowY + sortRowH - T.px(1), w, true)

    -- --------------------------------------------------------
    -- ZONE 3: Draggable container buttons (all but main, in display order)
    -- Scrollable if overflow. Stencil-clipped.
    -- --------------------------------------------------------
    local listStartY = curY

    -- Zone 3 lists every container but main (idx 1, the permanent Zone 1
    -- pin), in display order.
    local listEntries = {}
    for _, ci in ipairs(order) do
        if ci ~= 1 then
            listEntries[#listEntries + 1] = ci
        end
    end

    -- Check if scroll needed
    local totalListH = #listEntries * T.px(CONTAINER_BTN_SZ)
    local scrollArrowH = 0
    local scrollOff = win._stripScrollOffset or 0
    local listAreaH = h - listStartY
    local needsScroll = totalListH > listAreaH
    if needsScroll then
        scrollArrowH = T.px(STRIP_SCROLL_ROW_H)
        listAreaH = h - listStartY - scrollArrowH
        local maxScroll = totalListH - listAreaH
        if maxScroll < 0 then maxScroll = 0 end
        scrollOff = math.max(0, math.min(scrollOff, maxScroll))
        win._stripScrollOffset = scrollOff
    else
        win._stripScrollOffset = 0
        scrollOff = 0
    end
    -- Where the buttons sit (panel-local), for the controller's
    -- stops (_buildLootFocusables)
    do
        local L = win._stripLay or {}
        win._stripLay = L
        L.listY, L.listH, L.scroll, L.entries = listStartY, listAreaH, scrollOff, listEntries
    end

    -- Store button Y positions for drag insertion
    win._stripBtnMidpoints = {}

    -- Stencil clip the list area
    self:setStencilRect(0, listStartY, w, listAreaH)

    -- Build selection lookup: containerIdx → column number (1-based from left)
    local mcSel = win._mcSelected or {}
    local mcSelMap = {}
    for colNum, selCI in ipairs(mcSel) do
        mcSelMap[selCI] = colNum
    end
    local viewedCI = win._viewedContainer  -- single-select view

    local btnY = listStartY - scrollOff
    for li, ci in ipairs(listEntries) do
        local cnt = containers[ci]
        if cnt then
            local isHover = (mx >= 0 and mx < w and my >= btnY and my < btnY + T.px(CONTAINER_BTN_SZ))
                            and my >= listStartY and my < listStartY + listAreaH and not cuesOn
            local isMcSel = mcSelMap[ci]
            local isViewed = (ci == viewedCI)

            -- One selected look for a shown bag (viewed, or one of the Loot
            -- tab's columns): the T.selectionA wash; else the hover wash. The
            -- controller's mark goes on after, so it shows on a selected bag.
            if isMcSel or isViewed then
                local ac = T.accent
                self:drawRect(T.px(1), btnY, w - T.px(1), T.px(CONTAINER_BTN_SZ), selA, ac.r, ac.g, ac.b)
            elseif isHover then
                local hv = T.hover
                self:drawRect(T.px(1), btnY, w - T.px(1), T.px(CONTAINER_BTN_SZ), hv.a, hv.r, hv.g, hv.b)
            end
            if isHover then ZeD.Help.set(self, ZeD.tr("UI_ZeD_CW_BagHelp", cnt.name or "")) end
            local onFocusC = false
            if gpFocusedCI == ci then
                onFocusC = ZeD.Focus.mark(self, T.px(1), btnY, w - T.px(1), T.px(CONTAINER_BTN_SZ), stripFocus)
            end

            -- Icon (the game's own box when it has none of its own; ZeD.genericContainerTex, ZeD_WorldWindow.lua)
            local tex = cnt.texture or (ZeD.genericContainerTex and ZeD.genericContainerTex())
            if tex then
                local ix = math.floor((w - iconSz) / 2)
                local iy = btnY + math.floor((T.px(CONTAINER_BTN_SZ) - iconSz) / 2)
                self:drawTextureScaledAspect(tex, ix, iy, iconSz, iconSz, 1, 1, 1, 1)
            else
                local glyph = string.sub(cnt.name or "?", 1, 1)
                local gw = ZeD.TM:MeasureStringX(font, glyph)
                local gx = math.floor((w - gw) / 2)
                local gy = btnY + math.floor((T.px(CONTAINER_BTN_SZ) - fontH) / 2)
                local color = onFocusC and T.textOnFocus or ((isMcSel or isViewed) and T.text or T.textDim)
                self:drawText(glyph, gx, gy, color.r, color.g, color.b, color.a, font)
            end

            -- other mods' marks on the button (StripDecorators.lua); before the badge below so the badge stays on top
            ZeD.StripDecorators.run(self, win, "char", cnt, T.px(1), btnY, w - T.px(1), T.px(CONTAINER_BTN_SZ))

            -- Column number badge (bottom-right corner)
            if isMcSel then
                local badge = tostring(isMcSel)
                local bw = ZeD.TM:MeasureStringX(font, badge)
                local bx = w - T.px(4) - bw
                local by = btnY + T.px(CONTAINER_BTN_SZ) - fontH - T.px(1)
                local bc = onFocusC and T.textOnFocus or T.text
                self:drawText(badge, bx, by, bc.r, bc.g, bc.b, bc.a, font)
            end

            -- Bottom border
            self:drawRect(T.px(1), btnY + T.px(CONTAINER_BTN_SZ) - T.px(1), w - T.px(1), T.px(1), bd.a, bd.r, bd.g, bd.b)

            -- Hit zone
            if btnY + T.px(CONTAINER_BTN_SZ) > listStartY and btnY < listStartY + listAreaH then
                self:addHitZone("cnt:" .. ci, 0, btnY, w, T.px(CONTAINER_BTN_SZ))
            end

            -- Store midpoint for drag insertion
            win._stripBtnMidpoints[li] = btnY + math.floor(T.px(CONTAINER_BTN_SZ) / 2)

            btnY = btnY + T.px(CONTAINER_BTN_SZ)
        end
    end

    -- Drag insertion marker (vertical = horizontal accent line between buttons)
    local drag = win._stripDrag
    if drag and drag.active and drag.insertIdx then
        local insertIdx = drag.insertIdx
        local markerY
        if insertIdx <= 1 then
            markerY = listStartY - scrollOff
        elseif insertIdx > #listEntries then
            markerY = listStartY - scrollOff + #listEntries * T.px(CONTAINER_BTN_SZ)
        else
            markerY = listStartY - scrollOff + (insertIdx - 1) * T.px(CONTAINER_BTN_SZ)
        end
        local ac = T.accent
        self:drawRect(T.px(4), markerY - T.px(1), w - T.px(8), T.px(2), ac.a, ac.r, ac.g, ac.b)
    end

    self:clearStencilRect()

    -- Store list entries for event handlers
    win._stripListEntries = listEntries

    -- --------------------------------------------------------
    -- SCROLL ARROWS (if needed)
    -- --------------------------------------------------------
    if needsScroll then
        local arrowY = h - scrollArrowH
        local sep2 = T.borderS
        self:drawRect(0, arrowY, w, T.px(1), sep2.a, sep2.r, sep2.g, sep2.b)

        local halfW = math.floor(w / 2)
        local maxScroll = totalListH - listAreaH
        local canScrollUp   = scrollOff > 0
        local canScrollDown = scrollOff < maxScroll

        -- Up button (left half)
        local hoverUp = canScrollUp and (mx >= 0 and mx < halfW and my >= arrowY and my < h) and not cuesOn
        if hoverUp then
            local hv = T.hover
            self:drawRect(T.px(1), arrowY + T.px(1), halfW - T.px(1), scrollArrowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
        end
        local upC = canScrollUp and (hoverUp and T.text or T.textDim) or T.border
        A.drawTriangleUp(self, math.floor((halfW - T.px(ARROW_SZ)) / 2), arrowY + math.floor((scrollArrowH - T.px(ARROW_SZ)) / 2), T.px(ARROW_SZ), upC)
        if canScrollUp then
            self:addHitZone("strip_scroll_up", 0, arrowY, halfW, scrollArrowH)
        end

        -- Down button (right half)
        local hoverDn = canScrollDown and (mx >= halfW and mx < w and my >= arrowY and my < h) and not cuesOn
        if hoverDn then
            local hv = T.hover
            self:drawRect(halfW, arrowY + T.px(1), halfW, scrollArrowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
        end
        local dnC = canScrollDown and (hoverDn and T.text or T.textDim) or T.border
        A.drawTriangleDown(self, halfW + math.floor((halfW - T.px(ARROW_SZ)) / 2), arrowY + math.floor((scrollArrowH - T.px(ARROW_SZ)) / 2), T.px(ARROW_SZ), dnC)
        if canScrollDown then
            self:addHitZone("strip_scroll_down", halfW, arrowY, halfW, scrollArrowH)
        end
    end
end

-- ============================================================================
-- PINNED SKILLS (ZeD_Pins: from the row's menu; three pins at most, all kinds)
-- ============================================================================


-- Pin or unpin a skill. Assigned to the forward-declared upvalue (not
-- `local function`), as skillRowMenu below is, so closures declared earlier
-- in the file can capture it.
togglePinSkill = function(win, skillName)
    -- (ZeD_Pins: every kind of pin in one list, three at most)
    ZeD.Pins.toggle(win._playerObj, "skill", skillName)
    win._pinnedSkills = ZeD.Pins.skillNames(win._playerObj)
end

-- A skill row's menu: a skill is pinned from here, never by a plain click.
skillRowMenu = function(win, skillName, ax, ay)
    if not skillName then return end
    local pd = ZeD.SkillsTab.getPinData(win._playerObj, skillName)
    ZeD.Pins.skillMenu(win._playerObj:getPlayerNum(), skillName, pd and pd.name or skillName, ax, ay)
end

-- ============================================================================
-- VANILLA VISIBILITY GATE
-- ============================================================================

-- The game's inventory and loot pages of every local player whose windows are ZeD's (ZeD.windowsFor: player 1, and
-- players 2 to 4 with split view on) are hidden, never removed: the game's timed actions and refreshes still read them
-- (getPlayerData(pn)). pn: one player's only.
local function _hideVanilla(pn)
    -- safe mode (SafeMode.lua): the game's own pages stay as they are
    if ZeD.Safe.on("windows") then return end
    for p = (pn or 0), (pn or 3) do
        if ZeD.windowsFor(p) then
            local vi = getPlayerInventory(p)
            local vl = getPlayerLoot(p)
            if vi then vi:setVisible(false) end
            if vl then vl:setVisible(false) end
        end
    end
end

-- Gamepad Y button vanilla takeover.
-- When gamepad Y is pressed and no element has joypad focus (exactly our
-- windowshade-released state), the engine dispatches through
-- `JoypadControllerData:onPressButtonNoFocus` which ultimately calls
-- `ISButtonPrompt:onYPress` on the player's active ButtonPrompt. Vanilla's
-- onYPress reads `self.yFunc` — cached via setYPrompt as a direct reference
-- to `ISButtonPrompt.cmdShowInventory` — and fires it, showing the vanilla
-- inventory panel.
--
-- We override `onYPress` to a no-op. Overriding `cmdShowInventory` alone
-- wouldn't work because setYPrompt captures the old function reference.
-- Replacing `onYPress` itself is method-lookup through the class metatable,
-- so the override applies instantly.
--
-- Why no-op and not "route to toggleBothPaired directly": FocusManager's
-- OnTick polling already detects Y rising-edge when no window is focused
-- and runs it through the tap/hold state machine (< 400ms → `_handleYTap`
-- which opens both / cycles / etc.). Letting onYPress ALSO fire the open
-- immediately would double-fire or fight the tap/hold timing. Keeping a
-- single path (FocusManager OnTick) keeps Y semantics consistent whether
-- a window is focused or not.
-- In safe mode (SafeMode.lua) vanilla's own onYPress runs again: Y opens the
-- game's inventory, and FocusManager's tap opens nothing (toggleBothPaired).
if ISButtonPrompt then
    local _vanillaOnYPress = ISButtonPrompt.onYPress
    ISButtonPrompt.onYPress = function(self)
        -- (and for split-screen's other players, whose pads FocusManager does not read: the game's inventory, ZeD.windowsFor)
    if _vanillaOnYPress and (ZeD.Safe.on("windows") or not ZeD.windowsFor(self.player)) then return _vanillaOnYPress(self) end
    end
end

--- True while the Character window is open. pn: whose window (nil: the first player's).
function ZeD_CharacterWindow.isOpen(pn)
    return _charWins[pn or 0] ~= nil
end

--- Rebuild the controller's stops for the tab on show. Reset windows
--- (Organisms.lua) sets Loot without a tab switch, and the old tab's stops
--- would stay registered until the next change.
function ZeD_CharacterWindow.syncRing(win)
    win = win or ZeD_CharacterWindow.getWindow()
    if win and win._mainContent and _syncRingZonesToActiveTab then _syncRingZonesToActiveTab(win, win._mainContent) end
end

--- The open Character window, or nil (the same as getInstance). pn: whose window (nil: the first player's).
function ZeD_CharacterWindow.getWindow(pn)
    return _charWins[pn or 0]
end

--- The window open on a tab (a ticket note's Open key), as ZeD_WorldWindow.openTab does for its
--- side. Overrides/CharacterInfo.lua requires this file and defines openTab again (with a third
--- argument, toggle), so that later definition is the one in use.
function ZeD_CharacterWindow.openTab(playerNum, tabId)
    if not ZeD.windowsFor(playerNum) then return false end   -- (split-screen: the game's own, ZeD.windowsFor)
    if not _charWins[playerNum or 0] then
        local ok = pcall(ZeD_CharacterWindow.toggle, playerNum or 0)
        if not ok then return false end
    end
    local win = _charWins[playerNum or 0]
    if not win then return false end
    if win.windowShaded then
        win._autoShaded = false
        win:setWindowShaded(false)
        win._outSince = getTimestampMs() + 500
    end
    if win._activeTab == tabId and win._drawerMode == "tab" and win._drawerOpen == true then return true end
    local function attempt()
        local strip = win._tabStripPanel
        if strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:" .. tabId then
                    strip:onMouseDown(z.x + 2, z.y + 2)
                    return true
                end
            end
        end
        return false
    end
    if not attempt() then
        local tries = 0
        local function tick()
            tries = tries + 1
            if attempt() or tries >= 20 then Events.OnTick.Remove(tick) end
        end
        Events.OnTick.Add(tick)
    end
    return true
end

-- ============================================================================
-- TOGGLE
-- ============================================================================

--- Open the Character window for playerNum, or close it (saving its layout) if it is open.
function ZeD_CharacterWindow.toggle(playerNum)
    playerNum = playerNum or 0
    -- (split-screen: another player's press never opens or closes the first player's window, ZeD.windowsFor)
    if not ZeD.windowsFor(playerNum) then return end

    if _charWins[playerNum] then
        saveCharState(_charWins[playerNum])
        -- Tear down the joypad focus registration before dropping the ref.
        -- unregisterWindow releases the focus too, and is safe to call on an
        -- unfocused/unregistered window (no-op), so no guards needed.
        if ZeD and ZeD.Input and ZeD.Input.Focus then
            ZeD.Input.Focus.unregisterWindow(_charWins[playerNum])
        end
        if ZeD.TabFind then ZeD.TabFind.onClose(_charWins[playerNum]) end
        _charWins[playerNum]:removeFromUIManager()
        _charWins[playerNum] = nil
        _hideVanilla()
        return
    end

    -- safe mode (SafeMode.lua): the window does not open; callers fall back to vanilla's
    if ZeD.Safe.on("windows") then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local r = getR()
    local T = ZeD.T
    -- (the screen the window lives on, ZeD.screenOf: screenL, screenT its left and top)
    local screenW, screenH, screenL, screenT = ZeD.screenOf(playerNum)
    local maxWinW = math.floor(screenW * 0.5)
    local invW = 372                                     -- design units (default inventory width)
    -- (narrower where a full card beside it would shift the window: ZeD.Scale.fitInvW; it grows left from here)
    local fitU = ZeD.Scale and ZeD.Scale.fitInvW and
        ZeD.Scale.fitInvW(T, math.min(maxWinW, math.floor(screenW / 2) - T.px(5)), TAB_STRIP_W + CONTAINER_STRIP_W)
    if type(fitU) == "number" then invW = fitU end
    local winW = T.px(TAB_STRIP_W) + T.px(invW) + T.px(CONTAINER_STRIP_W)  -- 36 + 372 + 36 = 444 design units
    winW = math.min(winW, maxWinW)
    local winH = math.min(T.px(420), screenH - T.px(80))

    -- Position: left page of two-page spread, right edge 5px left of center
    local win = ZeD_Window:new(
        screenL + math.floor(screenW / 2) - winW - T.px(5), screenT,
        winW, winH,
        ZeD.tr("UI_ZeD_Char_Window")
    )
    win:initialise()
    win:addToUIManager()
    -- the game's own roll-up when not in use, each half on its own (WindowHalves, attached with the
    -- curtain below); the pins kept with the character
    win.autoCollapse = true
    win.minimumHeight = T.px(220)
    win._maxWinW = maxWinW
    win.playerNum = playerNum   -- (read as `win.playerNum or 0` by the doll, the equipment tab, the roll-up)
    _charWins[playerNum] = win
    _hideVanilla()

    -- Stable label for FocusManager diagnostic logs. win.title mutates across
    -- the session (gets replaced with the player's name mid-frame), so
    -- _label() in FocusManager prefers _zedLabel when set. Keeps console.txt
    -- grep-able as "Character" no matter what the title happens to read.
    win._zedLabel = "Character"

    -- registerWindow can fire early; ring construction + claimFocus are
    -- deferred to after win._containers / win._activeContainer are populated
    -- (further down in this function) so containerStrip elements seed correctly.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        ZeD.Input.Focus.registerWindow(win)
    end

    -- Override close so X-button clears this player's _charWins entry + hides vanilla
    win.close = function(self)
        saveCharState(self)
        -- Drop joypad focus before teardown. unregisterWindow
        -- internally calls releaseFocus if this window currently holds it,
        -- so one call handles both concerns.
        if ZeD and ZeD.Input and ZeD.Input.Focus then
            ZeD.Input.Focus.unregisterWindow(self)
        end
        -- (the pad keyboard typing into a Find field goes with the window; the text does too)
        if ZeD.TabFind then ZeD.TabFind.onClose(self) end
        self:removeFromUIManager()
        _charWins[self.playerNum or 0] = nil
        _hideVanilla()
    end

    -- Active tab state
    win._activeTab = "loot"
    win._tabScrollOffset = 0
    win._baseInvW = invW                 -- DESIGN UNITS (T.px() at every use; saved as-is)
    if type(fitU) == "number" then win._fitInvW, win._fitFromInvW = fitU, 372 end   -- (saved as 372 until a resize)
    win._anchorRightEdge = win:getX() + winW

    -- Container state
    win._playerObj = playerObj
    win._containers = buildContainers(playerObj)
    win._activeContainer = 1
    win._containerTimer = 0
    win._containerDueMs = getTimestampMs() + 500   -- (the World window's falls WREF.phaseMs later)
    win._containerSortMode = "dist"  -- "dist" | "wt" | "type"
    win._containerOrder = nil        -- nil = natural order; set by sort/drag

    -- Radio contextual tab state. _kind tells RadioTab.render which
    -- discovery source to use ("char" -> equipped scan). Refreshed on the
    -- same 30-frame timer as containers (see win._containerTimer block).
    win._kind             = "char"
    win._radios           = ZeD.RadioTab.buildEquippedRadios(playerObj)
    win._radioIdx         = 1
    win._radioWaveCache   = {}

    -- Multi-container state
    win._mcSelected = {}          -- ordered array of extra container indices (not main)
    win._mcColStates = {}         -- per-column state for renderMultiColumnContent
    win._mcPrevTab = nil          -- (these three stay nil: nothing saves or reads them)
    win._mcPrevDrawerMode = nil
    win._mcPrevDrawerOpen = nil
    -- Gamepad state for the charMC<n> column zones. _gpFocusedMCItem tracks
    -- the focused Java item for identity preservation across per-frame refresh;
    -- _gpFocusedMCColIdx is its column (for scroll-follow + future per-column
    -- dispatch); _lastPinnedMCItem is the scroll-follow delta gate's cache.
    win._gpFocusedMCItem     = nil
    win._gpFocusedMCColIdx   = nil
    win._lastPinnedMCItem    = nil

    -- Inventory drawer state (two-drawer architecture)
    win._invDrawerOpen    = true    -- inventory drawer starts open
    win._invDrawerEffW    = T.px(invW)    -- current animated width (screen px)
    win._invDrawerTargetW = T.px(invW)    -- animation target (screen px)
    win._mainVisible      = true    -- on-person container visible (toggleable on Loot)

    -- Viewed container state — single-select on non-equip tabs
    win._viewedContainer = nil    -- container index override for display (nil = main)

    -- Ring model: five zones at open, plus one per open Loot column. A tab's
    -- whole drawer is one logical zone (charTabContent) — e.g. disclosure +
    -- equipment slots on Equip — D-pad navigates within; LB/RB only hops
    -- among zones. Zone order (LB/RB cycle direction):
    --   charTabBar          always focusable, one element per visible tab
    --   charTabContent      per-tab drawer content (disclosure+slots on equip,
    --                       the band / skill rows / ... on other tabs)
    --   charMC1..charMCN    one per Loot column (added by _rebuildCharMCRingZones)
    --   charMainInv         always the main inventory list (invrows from player inv)
    --   charItemCard        item card action strip (focusable while a card is open)
    --   charContainerStrip  container buttons, focusable on every tab
    -- Initial _focusIdx = 3 (charMainInv) so Y-tap lands cursor on inv items.
    if ZeD and ZeD.Input and ZeD.Input.Focus then
        local Focus = ZeD.Input.Focus

        local activeTab = win._activeTab or "loot"

        local tabEls = _buildTabBarElements(win)
        _attachTabBarCallbacks(win, tabEls)

        local tabContentEls = _buildPanelFocusables(win, win._mainContent, activeTab) or {}
        local mainInvEls    = _buildInvRowFocusables(win) or {}
        -- The MC columns' stops (Loot + multi-column only): {} on first open
        -- (no slot given, no columns yet), and not put in the ring; the
        -- charMC<n> zones appear when mcToggleContainer fires
        -- _syncRingZonesToActiveTab.
        local mcColumnEls   = _buildCharacterMCColumnFocusables(win) or {}
        -- Containers reachable on ALL tabs (D-pad cycles + A activates). MC
        -- toggle is Loot-only and enforced inside container onActivate.
        local containerEls  = _buildLootFocusables(win) or {}

        -- uiRange fns declare the horizontal x,w range of each zone on
        -- the window's title bar, used by ZeD_Window's scoped-underline focus
        -- indicator. Dynamic values (drawer width, window width) read live.
        local function _drawerRange(w)
            local T = ZeD.T
            return T.px(TAB_STRIP_W), math.floor(w._drawerEffW or 0)
        end
        -- The main inv zone's underline spans ONLY the last (rightmost)
        -- column when MC is active. Computed from content._colStates so the
        -- cue tracks the dynamic column layout. Falls back to full inv width
        -- when single-column.
        local function _invRange(w)
            local T = ZeD.T
            local dw = math.floor(w._drawerEffW or 0)
            local baseX = T.px(TAB_STRIP_W) + dw
            local cnt = w._mainContent
            local cs = cnt and cnt._colStates
            if cs and #cs >= 2 then
                local last = cs[#cs]
                if last and last.renderX and last.renderW then
                    return baseX + last.renderX, last.renderW
                end
            end
            return baseX, (w._baseInvW and T.px(w._baseInvW)) or (w:getWidth() - T.px(TAB_STRIP_W) - dw - T.px(CONTAINER_STRIP_W))
        end

        -- The Equip tab's drawer has no zone of its own: its disclosure and
        -- equipment slots are elements of charTabContent, as every tab's are.
        -- LB/RB only hops between zones (tabBar / drawer / MC / mainInv /
        -- card / container); D-pad handles intra-drawer navigation.
        win._focusRing = {
            { zone = "charTabBar",
              focusable = true,
              elements = tabEls,
              focusedElementIdx = _findActiveTabIdx(tabEls, activeTab),
              uiRange = function(w) return 0, ZeD.T.px(TAB_STRIP_W) end },
            { zone = "charTabContent",
              focusable = #tabContentEls > 0,
              elements = tabContentEls,
              focusedElementIdx = 1,
              -- (an item card over the drawer hides the tab's controls)
              covered = function(w) return w._drawerItem ~= nil end,
              uiRange = _drawerRange },
            { zone = "charMainInv",
              focusable = #mainInvEls > 0,
              elements = mainInvEls,
              focusedElementIdx = 1,
              landOn = _charInvListLandOn,
              uiRange = _invRange },
            -- (The per-column MC zones, charMC1..charMCN, are inserted by
            -- _rebuildCharMCRingZones() below, just BEFORE charMainInv: Loot
            -- with columns open only, their stops rebuilt from
            -- content._colStates by the per-frame refresh.)
            -- Item card action strip. Focusable while a card is open, over the
            -- inventory or over a tab (the per-frame refresh below). Buttons in
            -- the card's own order (_buildCardActionFocusables).
            { zone = "charItemCard",
              focusable = false,
              elements = {},
              focusedElementIdx = 1,
              landOn = Focus.landOnPrimary,   -- (into a card, onto its primary action)
              uiRange = _drawerRange },
            { zone = "charContainerStrip",
              focusable = #containerEls > 0,
              elements = containerEls,
              focusedElementIdx = (function()
                  -- Seed by containerIdx match (elements are in
                  -- [main, non-main display-order] layout, not container-index
                  -- order).
                  if not win._activeContainer or #containerEls == 0 then return 1 end
                  for i, el in ipairs(containerEls) do
                      if el.containerIdx == win._activeContainer then return i end
                  end
                  return 1
              end)(),
              landOn = _charStripLandOn,
              uiRange = function(w)
                  local T = ZeD.T
                  return w:getWidth() - T.px(CONTAINER_STRIP_W), T.px(CONTAINER_STRIP_W)
              end },
        }
        -- Build the per-column MC zones (no-op while no columns are open).
        _rebuildCharMCRingZones(win)
        win._focusIdx = 3  -- start on charMainInv (invrows)
        -- Entering the window lands on the list's first row once
        -- it has rows (Focus.ensureEntry; World window parity)
        win._focusEntryZone    = "charMainInv"
        win._focusPendingEntry = true

        Focus.claimFocus(win)
    end

    -- Health tab state
    win._healthScroll = ZeD_ScrollbarState:new()
    win._healthScroll.visible = false
    win._healthCache       = nil
    win._healthBodyFigure    = nil
    win._healthHoveredPart   = nil
    win._healthActivePart    = nil  -- gamepad: resolved part (gp focus overrides mouse hover), as Thermal's
    win._healthBand          = nil  -- the footer band's rects (HealthTab._renderBand): exercise box, - / +, Start
    win._healthMenuOpen      = false  -- the exercise pop-up list
    win._healthInjuryZones   = nil -- gamepad: stamped each frame by injury draw loop
    win._healthInjuryYMap    = nil  -- gamepad: scroll-follow Y-stamps keyed by body part name
    win._healthContentPanel  = nil  -- gamepad: panel ref for _onPartClicked anchor fallback
    win._healthFigureExpanded = true
    win._healthFigureZone     = nil

    -- Skills tab state
    win._skillsScroll = ZeD_ScrollbarState:new()
    win._skillsScroll.visible = false
    win._skillsCache  = nil
    win._skillsGridExpanded = true
    win._skillsGridZone     = nil
    win._trainingCache     = nil
    win._trainingExpanded  = {}
    win._trainingGroupZones = nil
    win._skillRowZones     = nil

    -- Pinned skills (ZeD_Pins: three pins at most of every kind, from the menus; the skill ones mark their rows)
    win._pinnedSkills = ZeD.Pins.skillNames(playerObj)

    -- Equipment tab state (slot list + defense dashboard)
    win._equipListExpanded     = true   -- pinned "Equipped" disclosure default
    win._equipProtCache        = nil
    win._equipDefBodyFigure    = nil
    win._equipDefHoveredPart   = nil
    win._equipDefenseZone      = nil

    -- Thermal tab state
    win._thermalScroll = ZeD_ScrollbarState:new()
    win._thermalScroll.visible = false
    win._thermalCache       = nil
    win._thermalTimer       = 0
    win._thermalBodyFigure  = nil
    win._thermalHoveredPart = nil
    win._thermalActivePart  = nil  -- gamepad: resolved part (gp focus overrides mouse hover)
    win._thermalView        = 1
    win._thermalBand        = nil  -- the footer band's View box (ThermalTab._renderBand)
    win._thermalMenuOpen    = false  -- the View pop-up list
    win._thermalFigureExpanded = true
    win._thermalFigureZone     = nil

    -- Journal tab state
    win._journalSubTab      = 1     -- the open page: 1=Journal, 2=Notebooks, 3=Papers, 4=Recipes, 5=Loadouts
    win._journalSubTabZones = nil   -- (nothing reads it: the pages are the header's Page pop-up, not a strip)
    win._mapDragging        = false -- (a map pan-drag; Maps is the World window's, see the map state below)
    win._journalScroll = ZeD_ScrollbarState:new()
    win._journalScroll.visible = false
    win._journalCache  = nil
    win._killsExpanded = false
    win._killsRowY     = 0     -- Y position of kills stat row (for click detection)
    win._killsRowH     = 0     -- height of kills stat row
    win._journalGroupCollapsed = {}   -- month_year key → bool
    win._journalGroupZones     = nil  -- click zones for group headers
    win._journalDeleteZones    = nil  -- click zones for entry delete X buttons
    -- Gamepad: extra zones stamped by JournalTab.render for the kills
    -- disclosure row and save button — enables gamepad focusables that don't
    -- depend on a per-entry loop (kills + save are fixed-position on the
    -- Journal sub-tab).
    win._journalKillsZone     = nil
    win._journalSaveBtnZone   = nil
    -- Gamepad: scroll-follow delta gate. Scroll-follow pins scroll
    -- only when the focused id CHANGES, not every frame the mode gate still
    -- thinks we're on gamepad. Prevents input-mode oscillation from locking
    -- the scroll when kbm briefly fires mid-gamepad-nav.
    win._lastPinnedJournalId  = nil
    -- Recipe notebook state (journal Recipes sub-tab — CraftingCore readOnly)
    win._jrecipeState = nil   -- lazily created by JournalTab.getJRecipeState
    -- Map annotation toolbar state. The Maps page lives in the World window
    -- (MapsTab, on that window's own fields); nothing in this window reads these.
    win._mapActiveTool    = nil   -- active tool id (nil = pan mode)
    win._mapActiveColor   = 1     -- color palette index
    win._mapToolZones     = nil   -- click zones for tool buttons
    win._mapColorZones    = nil   -- click zones for color swatches
    win._mapToolsExpanded = false -- disclosure triangle state
    win._mapDisclosureZone = nil  -- click zone for disclosure chevron
    win._mapToolRMBZones  = nil   -- RMB zones for pin toggling in expanded view

    -- Identity tab state
    win._identityScroll = ZeD_ScrollbarState:new()
    win._identityScroll.visible = false
    win._identityCache  = nil
    win._identityTimer  = 0
    win._identityPhotoExpanded = false
    win._identityPhotoRect = nil   -- drawer-relative photo frame rect (set by IdentityTab renderer)
    win._identityScrollOff = 0
    -- Gamepad: tab-header disclosure hit-zone (stamped each frame by
    -- IdentityTab.render) + grid-scroll pseudo-zone rect (stamped when the
    -- content overflows the viewport).
    win._identityFigureZone     = nil
    win._identityGridScrollZone = nil

    -- Equipment tab state
    win._equipScroll = ZeD_ScrollbarState:new()
    win._equipScroll.visible = false
    win._equipCache       = nil
    win._equipExpanded    = {head = false, torso = false, arms = false, legs = false, held = false}
    win._equipSelected    = nil   -- selected slot type string or nil
    win._equipGroupZones  = {}
    win._equipSlotZones   = {}
    win._equipBackZone    = nil
    win._equipActionZones = {}
    win._equipBodyFigure  = nil
    win._equipCardH       = 0
    win._equipColWidths   = nil   -- resizable column widths (lazy-init in EquipmentTab)
    win._equipColDrag     = nil   -- active column drag state
    win._equipDivZones    = nil   -- column divider hit zones

    -- Body geometry
    local bodyY = win:getBodyY()
    local bodyH = win:getBodyHeight()

    -- Forward declarations — created below, but closures need the upvalues
    local content
    local containerStrip

    -- Tab strip panel — left edge, fixed TAB_STRIP_W (36 units) wide
    local strip = ZeD_Panel:new(0, bodyY, T.px(TAB_STRIP_W), bodyH)
    strip._zedLabel = "char tab strip"   -- its own name in console.txt and safe mode's watchdog
    strip.anchorRight = false
    strip:initialise()
    win:addChild(strip)
    -- Exposed for FocusManager._collectFlat's panel-offset translation.
    win._tabStripPanel = strip

    strip._onPrerender = function(self) drawTabStrip(self, win) end

    strip.onMouseDown = function(self, x, y)
        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id
        local T = ZeD.T
        -- Tab scroll arrows
        if zid == "tab_scroll_up" then
            win._tabScrollOffset = (win._tabScrollOffset or 0) - T.stripH
            return true
        elseif zid == "tab_scroll_down" then
            win._tabScrollOffset = (win._tabScrollOffset or 0) + T.stripH
            return true
        end
        if type(zid) == "string" and zid:sub(1, 4) == "tab:" then
            local tabId = zid:sub(5)
            -- MC columns stay open on the way to Loot; any other tab closes them (below)
            local mcSel = win._mcSelected or {}
            local mcActive = #mcSel > 0

            if tabId == "loot" then
                -- LOOT: snap to inventory-only state (no cross-animation).
                -- A rolled side comes down first: the snap below measures the
                -- whole window (the side was added on top of it afterwards).
                if win._rolled then ZeD.Curtain.finishUnroll(win) end
                win._activeTab  = "loot"
                win._drawerItem = nil
                win._drawerMode = nil
                win._drawerOpen = false
                win._tabUnder = nil
                content._selectedItems = {}
                content._lastClickedItem = nil
                -- Snap to base inventory width
                local baseInv = T.px(win._baseInvW or 372)
                win._drawerEffW  = 0
                win._prevEffW    = 0
                win._invDrawerOpen = true
                local snapW = T.px(TAB_STRIP_W) + baseInv + T.px(CONTAINER_STRIP_W)
                win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                win:setWidth(snapW)
                local snapX = win._anchorRightEdge - snapW
                win:setX(snapX)
                win._lastSetX = snapX
            elseif tabId == win._activeTab then
                -- Same tab clicked → toggle drawer open/closed
                if win._drawerOpen and win._drawerMode == "tab" then
                    -- Closing tab drawer: if inventory is hidden, reopen it first
                    if not win._invDrawerOpen then
                        win._invDrawerOpen = true
                        win._invDrawerTargetW = T.px(win._baseInvW or 372)
                    end
                    win._activeTab  = "loot"  -- back to inventory-only = loot view
                    win._drawerOpen = false
                    win._drawerMode = nil
                    win._tabUnder = nil
                    -- Keep _viewedContainer so L-tab returns to last viewed container
                    if tabId == "equip" then win._equipSelected = nil end
                else
                    if not win._drawerOpen then
                        win._preDrawerW = win:getWidth()
                    end
                    win._drawerMode = "tab"
                    win._drawerOpen = true  -- triggers window growth animation
                    win._drawerItem = nil
                    win._tabUnder = nil
                end
            else
                -- New tab → switch drawer content
                -- MC exit FIRST (before saving pre-drawer width)
                if mcActive and tabId ~= "loot" then
                    exitMultiContainer(win, content)
                    -- Snap window to base size before drawer opens
                    local baseInv = T.px(win._baseInvW or 372)
                    local snapW = T.px(TAB_STRIP_W) + baseInv + T.px(CONTAINER_STRIP_W)
                    win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                    win:setWidth(snapW)
                    local snapX = win._anchorRightEdge - snapW
                    win:setX(snapX)
                    win._lastSetX = snapX
                end
                -- NOW save pre-drawer width (after MC snap, so it's the correct base)
                if not win._drawerOpen then
                    win._preDrawerW = win:getWidth()
                end
                win._activeTab = tabId
                win._drawerMode = "tab"
                win._drawerOpen = true
                win._drawerItem = nil
                win._tabUnder = nil
                -- Reset tab scroll + cache
                local scroll = getActiveScroll(win)
                if scroll then scroll:setScrollPos(0) end
                win._healthCache = nil
                win._skillsCache = nil
                win._trainingCache = nil
                win._equipProtCache = nil
                win._thermalCache = nil
                win._identityCache = nil
                win._identityPhotoRect = nil  -- clear avatar overlay rect on tab switch
                win._equipCache = nil
                win._equipSelected = nil
                -- Clear item selection
                content._selectedItems = {}
                content._lastClickedItem = nil
            end
        end
        -- Every strip click re-syncs the gamepad ring zones, as the gamepad
        -- path (_switchTabForNav) does: without it, after Journal -> Loot the
        -- charTabContent zone still held the Journal's stops and D-pad right
        -- from the inventory landed on invisible elements.
        if _syncRingZonesToActiveTab then _syncRingZonesToActiveTab(win, content) end
        return true
    end

    strip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local totalTabH = measureTabStripH(win)   -- (win: a tab shown only sometimes is counted right)
        if totalTabH > self:getHeight() then
            win._tabScrollOffset = (win._tabScrollOffset or 0) + del * T.stripH
            return true
        end
        return false
    end

    -- ----------------------------------------------------------------
    -- DRAWER — slides out between tab strip and inventory list
    -- ----------------------------------------------------------------
    win._drawerOpen     = false
    win._drawerEffW     = 0      -- pixel-based animation (a width in px, not a 0-1 progress)
    win._prevEffW       = 0      -- (a restored tab drawer's first frame widens the window too; nil lost it)
    win._drawerItem     = nil
    win._drawerMode     = nil    -- 'item' | 'tab' | nil
    win._tabUnder       = nil    -- saved tab id for snap-back

    -- Restore saved position, size, tab, drawer state
    restoreCharState(win, playerObj)

    local drawer = ZeD_Panel:new(T.px(TAB_STRIP_W), bodyY, 0, bodyH)
    drawer._zedLabel = "char drawer"   -- its own name in console.txt and safe mode's watchdog
    drawer.anchorRight = false
    drawer:initialise()
    win:addChild(drawer)
    win._drawerPanel = drawer

    -- Journal entry input (ZeD_TextEntry — real keyboard handling)
    local T = ZeD.T
    local journalInput = ZeD_TextEntry:new(0, 0, T.px(200), T.px(48), ZeD.tr("UI_ZeD_Char_JournalWrite"))
    journalInput:initialise()
    journalInput:setVisible(false)
    drawer:addChild(journalInput)
    win._journalInput = journalInput

    -- Journal save button: the entry with its ticked tags (ZeD.JournalTab.save; Into a
    -- notebook, the character writes it there first and the log keeps it after)
    local saveBtn = ZeD.Molecules.Button(0, 0, nil, getText("UI_btn_save"), nil, function()
        ZeD.JournalTab.save(win, journalInput:getText())
    end)
    saveBtn:initialise()
    saveBtn:setVisible(false)
    drawer:addChild(saveBtn)
    win._journalSaveBtn = saveBtn

    -- Journal sub-tab search fields (ISPanel children of drawer, like craft/build search)
    local journalSearch = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("UI_ZeD_Char_JournalSearchEntries"))
    journalSearch:initialise()
    journalSearch:setVisible(false)
    journalSearch.onFilter = function(self, text)
        win._journalSearchText = text
        win._journalCache = nil
        win._journalScroll:setScrollPos(0)
    end
    drawer:addChild(journalSearch)
    win._journalSearch = journalSearch
    win._journalSearchText = ""

    local recipeSearch = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("IGUI_CraftingWindow_SearchRecipes"))
    recipeSearch:initialise()
    recipeSearch:setVisible(false)
    recipeSearch.onFilter = function(self, text)
        if win._jrecipeState then
            win._jrecipeState.search = text
            win._jrecipeState.filterDirty = true
        end
        win._jrecipeCache = nil
    end
    drawer:addChild(recipeSearch)
    win._jrecipeSearch = recipeSearch

    local flyerSearch = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("IGUI_FilterSearch"))
    flyerSearch:initialise()
    flyerSearch:setVisible(false)
    flyerSearch.onFilter = function(self, text)
        win._flyerSearchText = text
        if ZeD.JournalReaders then ZeD.JournalReaders.scroll(win):setScrollPos(0) end
    end
    drawer:addChild(flyerSearch)
    win._flyerSearch = flyerSearch
    win._flyerSearchText = ""

    -- Identity tab bust portrait — window-parented to avoid a stencil conflict.
    -- ISUI3DModel cannot be a child of any stencil-using panel (GL scissor kills
    -- Java 3D rendering). Parented on win directly; positioned each frame to overlay
    -- the photo frame in IdentityTab. addChild between containerStrip and itemDrawer.
    local BUST_ZOOM     = 19     -- head+shoulders crop (tune in-game)
    local BUST_Y_OFFSET = -0.875 -- shift model down to show full head (tune in-game)
    local identityModel = ISUI3DModel:new(0, 0, T.px(120), T.px(120))  -- (the Identity photo frame; PHOTO_SIZE is IdentityTab's local, nil here; resized every frame after)
    identityModel:initialise()
    identityModel:instantiate()
    identityModel:setState("idle")
    identityModel:setDirection(IsoDirections.S)
    identityModel:setIsometric(false)
    identityModel:setZoom(BUST_ZOOM)
    identityModel:setYOffset(BUST_Y_OFFSET)
    identityModel:setDoRandomExtAnimations(true)
    identityModel:setVisible(false)
    identityModel.javaObject:setVisible(false)
    identityModel._characterBound = false
    identityModel._didDrag = false
    win._identityModel = identityModel

    -- The model in its photo frame, for this frame's rect; true when it shows. Run here from the
    -- drawer's prerender, and again from IdentityTab.render once the card has published its rect,
    -- so a change of style or photo moves the model in the same frame as the card.
    win._placeIdentityModel = function(drawerW)
        local T = ZeD.T
        local pr = win._identityPhotoRect
        if not (pr and drawerW > 0 and win._drawerMode == "tab" and win._activeTab == "identity") then
            return false
        end
        -- an open item card lies over the tab's right part: the model (no clip reaches it) shows while clear of the card
        if win._drawerItem and pr.x + pr.w > getTargetDrawerW(win) - T.px(ITEM_CARD_W) then return false end
        -- A model can't be clipped (its own UI element; stencils don't reach it), so clamp it
        -- to the card's scroll view: top below the pinned tab header, bottom above the view's
        -- end (else it draws over the status line at small sizes). _idView is the view
        -- IdentityTab.render publishes, in the same frame as pr.
        local view = win._idView
        local top, bot = pr.y, pr.y + pr.h
        if view then
            top = math.max(top, view.y)
            bot = math.min(bot, view.y + view.h)
        else
            top = math.max(top, ZeD.Molecules.getTabHeaderH())
        end
        local avH = bot - top
        if avH <= T.px(20) then return false end   -- hide only if clipped to nothing
        identityModel:setX(T.px(TAB_STRIP_W) + pr.x)
        identityModel:setY(win:getBodyY() + top)
        identityModel:setWidth(pr.w)
        identityModel:setHeight(avH)
        -- the bust's crop or the whole body
        if pr.expanded then
            identityModel:setZoom(win._identityCustomZoom)
            identityModel:setYOffset(0)
        else
            identityModel:setZoom(BUST_ZOOM)
            identityModel:setYOffset(BUST_Y_OFFSET)
        end
        -- the portrait studio's camera button in the photo's bottom right corner, over the figure (punch list 145)
        local cam = win._studioBtn
        if cam then
            local s = T.px(18)
            cam:setX(identityModel.x + identityModel.width - s - T.px(4))
            cam:setY(identityModel.y + identityModel.height - s - T.px(4))
        end
        return true
    end
    win._identityCustomZoom = 0  -- scroll wheel zoom for expanded mode

    -- Click-to-toggle: detect click (non-drag) in onMouseUp
    local origOnMouseDown = identityModel.onMouseDown
    identityModel.onMouseDown = function(self, x, y)
        self._didDrag = false
        return origOnMouseDown(self, x, y)
    end

    local origOnMouseMove = identityModel.onMouseMove
    identityModel.onMouseMove = function(self, x, y)
        local T = ZeD.T
        if self.mouseDown and math.abs((self.dragX or 0) + x) > T.px(20) then
            self._didDrag = true
        end
        return origOnMouseMove(self, x, y)
    end

    -- a release reaches whatever is under the pointer, so the toggle only answers a press that
    -- began on the model (a press on the frame beside it puts the model under the pointer)
    identityModel.onMouseUp = function(self, x, y)
        local wasDrag = self._didDrag
        local pressed = self.mouseDown
        self.mouseDown = false
        self.dragX = 0
        self:setCapture(false)
        if pressed and not wasDrag and win._activeTab == "identity" then
            win._identityPhotoExpanded = not win._identityPhotoExpanded
            win._identityCustomZoom = 0  -- reset zoom on toggle
            -- Auto-scroll to top so full-body avatar is fully visible (ISUI3DModel can't partial-clip)
            if win._identityScroll then
                win._identityScroll:setScrollPos(0)
            end
        end
        return true
    end

    -- Scroll wheel zoom when expanded
    identityModel.onMouseWheel = function(self, del)
        -- on the Equip doll the wheel scrolls the tab, as anywhere else in it
        if win._activeTab == "equip" and drawer.onMouseWheel then
            return drawer.onMouseWheel(drawer, del)
        end
        if win._identityPhotoExpanded then
            win._identityCustomZoom = win._identityCustomZoom - del * 2
        end
        return true
    end

    -- ----------------------------------------------------------------
    -- ITEM DRAWER — overlay panel for ItemCard, renders ON TOP of tab drawer
    -- ----------------------------------------------------------------
    local itemDrawer = ZeD_Panel:new(T.px(TAB_STRIP_W), bodyY, 0, bodyH)
    itemDrawer._zedLabel = "char item drawer"   -- its own name in console.txt and safe mode's watchdog
    itemDrawer.anchorRight = false
    itemDrawer:initialise()
    -- addChild deferred: itemDrawer goes in after the drawer, content and strips (only
    -- the hint layer comes later) so it renders on top of them
    win._itemDrawerPanel = itemDrawer

    local card = ZeD_ItemCard:new(0, 0, T.px(ITEM_CARD_W), bodyH, "drawer", playerNum)
    card:initialise()
    card:setVisible(false)
    itemDrawer:addChild(card)
    win._itemCard = card
    -- the card's back key shuts the card, as B does (_buildCardActionFocusables' onCancel);
    -- without this handler a click on it does nothing.
    card.onBackClick = function()
        local content = win._mainContent
        if content and win._updateDrawer then
            local sel = content._selectedItems or {}
            for k in pairs(sel) do sel[k] = nil end
            content._selectedItems   = sel
            content._lastClickedItem = nil
            win._updateDrawer(content)
        end
    end

    itemDrawer._onPrerender = function(self)
        local T = ZeD.T
        local effectiveW = math.floor(win._drawerEffW)
        local targetW = getTargetDrawerW(win)
        local bodyH = win:getBodyHeight()
        self:setHeight(bodyH)

        local showCard = win._drawerItem ~= nil and effectiveW >= T.px(100)
        card:setVisible(showCard)

        if showCard then
            if win._drawerMode == "tab" then
                -- Item+tab: overlay at right edge of tab drawer
                self:setX(T.px(TAB_STRIP_W) + targetW - T.px(ITEM_CARD_W))
                self:setWidth(T.px(ITEM_CARD_W))
            else
                -- Item-only: same position as tab drawer, animating width
                self:setX(T.px(TAB_STRIP_W))
                self:setWidth(effectiveW)
            end
            card:setX(0)
            card:setWidth(math.min(self:getWidth(), T.px(ITEM_CARD_W)))
            card:setHeight(bodyH)
            -- over a tab's content the card draws its left edge (a structure line); alone in the
            -- drawer the window's own lines bound it (the waterfall's edge, the divider, the help line)
            card.overlayEdge = (win._drawerMode == "tab") and "left" or nil

            -- Background fill: surface 1 at the window's see-through, claimed so the
            -- body is not drawn under it as well (one layer, ZeD.Surface)
            local dh = self:getHeight()
            ZeD.Surface.fill(self, 0, 0, self:getWidth(), dh, "surf1")
        else
            self:setWidth(0)
        end

    end

    itemDrawer.onMouseWheel = function(self, del)
        if card:getIsVisible() then
            card:onMouseWheel(del)
        end
        return true
    end

    drawer._onPrerender = function(self)
        local T = ZeD.T

        -- Pixel-based animation toward per-tab target width
        local targetW = getTargetDrawerW(win)
        local effW = win._drawerEffW
        if effW ~= targetW then
            local dt = UIManager.getMillisSinceLastRender() / 1000.0
            if dt > 0.1 then dt = 0.1 end
            if effW < targetW then
                effW = math.min(effW + T.px(DRAWER_PX_SPEED) * dt, targetW)
            else
                effW = math.max(effW - T.px(DRAWER_PX_SPEED) * dt, targetW)
            end
            win._drawerEffW = effW
        end

        local effectiveW = math.floor(effW)
        -- its left edge too, every frame like its neighbours: a text size or scale change
        -- with the window open moves the tab strip's edge, and a left edge kept from the
        -- build put the drawer's right side under the inventory (it showed at the
        -- smallest text size)
        local dx = T.px(TAB_STRIP_W)
        if self:getX() ~= dx then self:setX(dx) end
        self:setWidth(effectiveW)

        -- Clear saved width when drawer finishes closing (and the push below: a closed drawer owes nothing)
        if effectiveW == 0 then
            win._preDrawerW = nil
            win._drawerCapPush = nil
            win._foldDebt = nil
        end

        -- Detect user drag: if X differs from what we set last frame, adjust anchor
        if win._lastSetX and win:getX() ~= win._lastSetX then
            win._anchorRightEdge = win._anchorRightEdge + (win:getX() - win._lastSetX)
        end

        -- ── The width model: the tab drawer's delta drives the window width,
        -- invW is always the residual. The inventory toggle snaps width directly. ──
        local prevEffW = win._prevEffW or effectiveW
        local drawerDelta = effectiveW - prevEffW
        win._prevEffW = effectiveW

        local mcActive = #(win._mcSelected or {}) > 0
        local screenW = ZeD.screenOf(win)
        -- When MC + item card are both active, cap maxW at the player's preferred
        -- inv width (_baseInvW) plus chrome — window expands enough to keep
        -- card visible alongside MC, but not to full screen, so the eviction
        -- loop below fires when MC columns can't all fit at MIN_COL_W.
        local mcItemCap = nil
        if mcActive and win._drawerMode == "item" then
            local baseInv = T.px(win._baseInvW or 372)
            mcItemCap = T.px(TAB_STRIP_W) + baseInv + effectiveW + T.px(CONTAINER_STRIP_W)
        end
        local maxW = mcItemCap
            or (mcActive and (screenW - T.px(10)))
            or (win._maxWinW or math.floor(screenW * 0.5))

        -- (a drawer its half folded, WindowHalves: the window narrows by the drawer alone, so the list beside it stays
        -- under a resting pointer; the width the cap took is owed until the drawer really closes, punch list 126)
        local folded = ZeD.Halves and ZeD.Halves.foldedTab and ZeD.Halves.foldedTab(win) ~= nil
        -- a fold that ended any other way than its own tab coming back. Another drawer opening (another tab, a card):
        -- the debt rides through it, kept from the at-rest clearing below, and is paid as that drawer closes, so the
        -- list stays put while it opens (QA's Mac recheck, Nov 10 2026: paying it at once held the list 53 px left for
        -- about 10 frames). The drawer shut (Loot, a reset): paid now, as the close would have. (The same tab back
        -- reopens the same width, which owes the same again: that keeps the debt as it is.)
        local sameBack = win._drawerOpen and win._drawerMode == "tab" and win._activeTab == win._wasFoldTab
        if win._wasFolded and not folded and not sameBack and (win._drawerCapLost or 0) > 0 and win._drawerOpen then
            win._foldDebt = win._drawerCapLost
        elseif win._wasFolded and not folded and not sameBack and (win._drawerCapLost or 0) > 0 then
            local cap = maxW - (win._rolled and (win._rollW or 0) or 0)
            local newW = math.min(win:getWidth() + win._drawerCapLost, cap)
            win._drawerCapLost = 0
            win:setWidth(newW)
            local newX = win._anchorRightEdge - newW
            local pushed = 0
            local lx = ZeD.screenLeftOf(win)   -- (the player's part's left edge: 0 but in split view)
            if newX < lx then pushed = lx - newX; newX = lx end
            win._drawerCapPush = pushed
            win:setX(newX)
            win._lastSetX = newX
        end
        win._wasFolded = folded
        win._wasFoldTab = folded and ZeD.Halves.foldedTab(win) or nil
        if drawerDelta ~= 0 then
            -- A card opening in MC mode expands the window like tab mode
            -- does, rather than evicting MC columns up front: shrinking the inv
            -- area and evicting the oldest column made MC collapse silently on
            -- an item pick. So the window always resizes by drawerDelta (the
            -- eviction loop below only drops columns that can't fit).
            -- The width the cap swallows while the drawer opens is given back while it
            -- closes, so the window returns to its width (the World window does the same)
            -- (a rolled side's width is the full width less the rolled-off part: the cap in those terms)
            local cap = maxW - (win._rolled and (win._rollW or 0) or 0)
            local want = win:getWidth() + drawerDelta
            local lost = win._drawerCapLost or 0
            local newW
            if drawerDelta > 0 then
                newW = math.min(want, cap)
                lost = lost + (want - newW)
            elseif folded then
                newW = math.min(want, cap)
            else
                local back = math.min(lost, -drawerDelta)
                -- a fold's debt riding through another drawer (above) is paid in step with that drawer's close, what
                -- is still owed shrinking with what is left of the drawer, so the list eases back to its place over
                -- the slide (QA's Mac run, Nov 11 2026, on test 4: paid as fast as the drawer narrowed, the list
                -- jumped 53 px in the close's first two frames). The last frame pays what is left.
                if win._foldDebt and prevEffW > 0 then
                    back = math.min(lost, math.floor(lost * (-drawerDelta) / prevEffW + 0.5))
                end
                lost = lost - back
                newW = math.min(want + back, cap)
            end
            win._drawerCapLost = lost
            win:setWidth(newW)
            -- The drawer grows leftwards from the anchored right edge. Where that would put the
            -- window past the screen's left edge the engine pins it at 0 (setX keeps a top-level
            -- panel on screen); that pin is remembered as a push, not read as a drag that moves
            -- the anchor (read as a drag, on the Steam Deck the first full-card open moved the
            -- window 4 px right for good). The anchor stays where it was,
            -- so the window lands back on it as the drawer narrows.
            local newX = win._anchorRightEdge - newW
            local pushed = 0
            local lx = ZeD.screenLeftOf(win)   -- (the player's part's left edge: 0 but in split view)
            if newX < lx then pushed = lx - newX; newX = lx end
            win._drawerCapPush = pushed
            win:setX(newX)
            win._lastSetX = newX
        else
            -- At rest: accept user resize
            if win:getWidth() > maxW then win:setWidth(maxW) end
            -- (a window the player made narrower than the cap has nothing to give back; a folded drawer's window is
            -- narrower by the drawer, not by the player)
            -- (what a fold left owed for the drawer after it stays owed: _foldDebt, above)
            if not folded and (win._drawerCapLost or 0) > 0 and win:getWidth() + (win._rolled and (win._rollW or 0) or 0) < maxW - 1 then
                win._drawerCapLost = math.min(win._drawerCapLost, win._foldDebt or 0)
            end
            win._lastSetX = win:getX()
            -- (a window pinned at the screen's edge by an open drawer keeps its anchor, less the push)
            win._anchorRightEdge = win:getX() + win:getWidth() - (win._drawerCapPush or 0)
        end


        -- invW is ALWAYS the residual. A rolled-up inventory side (WindowCurtain,
        -- right of the drawer) has no inventory and no container strip.
        ZeD.Curtain.sync(win)
        local cStripW = win._rolled and 0 or T.px(CONTAINER_STRIP_W)
        local invW = win._rolled and 0 or (win:getWidth() - T.px(TAB_STRIP_W) - effectiveW - cStripW)
        invW = math.max(invW, 0)

        -- Track baseInvW ONLY when user manually resized (not from our snaps).
        -- Compare current width to what _baseInvW would produce — if different, user dragged.
        -- (not while a drawer is folded: the width the cap holds back would be saved as a narrower inventory)
        if drawerDelta == 0 and effectiveW == 0 and not mcActive and invW > 0 and not folded then
            local expectedW = T.px(TAB_STRIP_W) + T.px(win._baseInvW or 372) + T.px(CONTAINER_STRIP_W)
            if win:getWidth() ~= expectedW then
                -- _baseInvW is stored in design units (screen px / T.scale);
                -- kept fractional so save/restore round-trips without drift.
                win._baseInvW = invW / (T.scale or 1)
            end
        end

        -- Dynamic min/max
        -- (never above the maximum, so a resize drag and the cap above agree)
        win.minimumWidth = math.min(maxW, T.px(TAB_STRIP_W) + effectiveW + (win._invDrawerOpen and not win._rolled and T.px(200) or 0) + cStripW)
        win.maximumWidth = maxW

        -- ── MC eviction: check columns fit at MIN_COL_W ──────────
        if mcActive and #(win._mcSelected) > 0 then
            local R = getR()
            local minColW = T.px(R.MIN_COL_W or 140)
            local totalCols = #win._mcSelected + (win._mainVisible and 1 or 0)
            local xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
            local usable = invW - (totalCols - 1) * xferW
            local perCol = totalCols > 0 and (usable / totalCols) or 0
            local evicted = false
            while perCol < minColW and #win._mcSelected > 0 do
                table.remove(win._mcSelected, 1)
                totalCols = #win._mcSelected + (win._mainVisible and 1 or 0)   -- (a hidden main takes no column: one extra stays)
                xferW = T.px(R.getXferW and R.getXferW(totalCols) or 32)
                usable = invW - (totalCols - 1) * xferW
                perCol = totalCols > 0 and (usable / totalCols) or invW
                evicted = true
            end
            if evicted then
                if #win._mcSelected == 0 then
                    exitMultiContainer(win, content)
                else
                    local colSel = {}
                    for _, ci in ipairs(win._mcSelected) do colSel[#colSel + 1] = ci end
                    -- main column = containers[1] (see mcToggleContainer).
                    if win._mainVisible then
                        colSel[#colSel + 1] = 1
                    end
                    content._selectedContainers = colSel
                    content._containers = win._containers
                    local R2 = getR()
                    R2.rebuildColStates(content)
                    content._activeCol = #colSel
                end
                win._invDrawerTargetW = computeInvDrawerTarget(win)
                -- Rebuild the per-column ring zones to reflect the new
                -- MC count after FIFO eviction.
                if _syncRingZonesToActiveTab then _syncRingZonesToActiveTab(win, content) end
            end
        end

        -- Content panel: positioned after tab drawer, width = residual invW
        content:setX(T.px(TAB_STRIP_W) + effectiveW)
        content:setWidth(math.max(invW, 0))
        content:setVisible(invW > 0)
        -- the content's prerender (the controller's stops) does not run while it is hidden: the
        -- drawer runs the refresh instead (without it, at 1280x720 and UI scale 2.0 every tab
        -- but Equip had no stops)
        if invW <= 0 and content._focusRefresh then content._focusRefresh(content) end

        -- Container strip stays right of inventory
        containerStrip:setX(T.px(TAB_STRIP_W) + effectiveW + invW)
        containerStrip:setVisible(not win._rolled)

        -- Sync all child heights to current window body (and the tops and the two
        -- strips' widths: a scale or text size change moves the title bar and the strips)
        local bodyH = win:getBodyHeight()
        local bodyY = win:getBodyY()
        strip:setHeight(bodyH)
        self:setHeight(bodyH)
        content:setHeight(bodyH)
        containerStrip:setHeight(bodyH)
        if strip:getY() ~= bodyY then strip:setY(bodyY) end
        if self:getY() ~= bodyY then self:setY(bodyY) end
        if content:getY() ~= bodyY then content:setY(bodyY) end
        if containerStrip:getY() ~= bodyY then containerStrip:setY(bodyY) end
        if itemDrawer:getY() ~= bodyY then itemDrawer:setY(bodyY) end
        if strip:getWidth() ~= T.px(TAB_STRIP_W) then strip:setWidth(T.px(TAB_STRIP_W)) end
        if containerStrip:getWidth() ~= T.px(CONTAINER_STRIP_W) then containerStrip:setWidth(T.px(CONTAINER_STRIP_W)) end

        -- Store divider position for top-Z drawing in itemDrawer
        win._dividerX = (effectiveW > 0 and invW > 0) and (T.px(TAB_STRIP_W) + effectiveW) or nil

        -- (the card's visibility is the item drawer overlay's)
        -- Show/hide journal input children (only in Journal sub-tab)
        local showJournal = effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "journal"
        local showJournalInput = showJournal and (win._journalSubTab or 1) == 1
        win._journalInput:setVisible(showJournalInput)
        win._journalSaveBtn:setVisible(showJournalInput)
        -- Show/hide journal search fields per sub-tab
        local subIdx = win._journalSubTab or 1
        win._journalSearch:setVisible(showJournal and subIdx == 1)
        win._jrecipeSearch:setVisible(showJournal and subIdx == 4)
        -- Notebooks (2) and Papers (3) share the one search box; the quick look hides it
        local JR = ZeD.JournalReaders
        win._flyerSearch:setVisible(showJournal and JR ~= nil and JR.searchVisible(win, subIdx))
        if JR then JR.syncChildren(win, showJournal and subIdx == 2) end
        if ZeD.JournalLists then ZeD.JournalLists.syncChildren(win, showJournal and subIdx == 5) end
        -- (No map panel here: the Maps page is the World window's, MapsTab.)

        -- other mods' tabs place or hide their own window-parented children
        ZeD_CharacterWindow.extFrame(win, effectiveW)

        -- An open item card over the tab: the tab's own boxes it would lie over
        -- hide (a child panel can't be cut by the drawer's clip; setTabCover). The boxes
        -- are the drawer's children, so the card's edge is measured in the drawer, as the
        -- tab's clip is (it was in the window, the tab strip's width too far right: a box
        -- under the card by less than that stayed over it). Save stays: the Journal sets
        -- it in the part the card leaves showing (ZeD.Molecules.bandRoom).
        if win._drawerItem ~= nil and win._drawerMode == "tab" then
            local coverWX = getTargetDrawerW(win) - T.px(ITEM_CARD_W)
            for _, c in ipairs({ win._journalInput, win._journalSaveBtn, win._journalSearch, win._jrecipeSearch, win._flyerSearch }) do
                if c and c:isVisible() and c:getX() + c:getWidth() > coverWX then c:setVisible(false) end
            end
            for _, c in pairs(win._findFields or {}) do
                if c:isVisible() and c:getX() + c:getWidth() > coverWX then c:setVisible(false) end
            end
        end

        -- ── Identity avatar positioning (window-parented: see the model's build) ──
        do
            local model = win._identityModel
            if model then
                -- Deferred character binding (avoids nil player during init)
                if not model._characterBound and win._playerObj then
                    model:setCharacter(win._playerObj)
                    model._characterBound = true
                end

                -- the license photo holds still (an idle's bowed head leaves a bust frame); the Equip
                -- doll, the same model, keeps its idles
                local still = win._activeTab == "identity"
                if model._zedStill ~= still then
                    model._zedStill = still
                    model:setDoRandomExtAnimations(not still)
                end

                local showAvatar = win._placeIdentityModel(effectiveW)
                local cam = win._studioBtn
                if cam then
                    local camOn = showAvatar and win._activeTab == "identity" or false
                    if cam:isVisible() ~= camOn then cam:setVisible(camOn) end
                end

                -- The Equip tab's doll (EquipDoll.lua): the same model, full body, in the
                -- doll's photo frame. A model can't be clipped, so a frame partly
                -- scrolled out shrinks to the part showing (as the Identity photo does).
                local dollLayer = win._equipDollLayer
                local showLines = false
                if not showAvatar and win._equipDollShown and win._equipDollPhoto
                   and effectiveW > 0 and win._drawerMode == "tab" and win._activeTab == "equip"
                   and not win._equipSelected and not win._drawerItem then
                    local ph = win._equipDollPhoto
                    local clip = win._equipDollClip
                    local bY = win:getBodyY()
                    local top, bot = ph.y, ph.y + ph.h
                    if clip then
                        top = math.max(top, clip.y)
                        bot = math.min(bot, clip.y + clip.h)
                    end
                    if bot - top > T.px(40) then
                        showAvatar = true
                        model:setX(T.px(TAB_STRIP_W) + ph.x)
                        model:setY(bY + top)
                        model:setWidth(ph.w)
                        model:setHeight(bot - top)
                        model:setZoom(0)
                        model:setYOffset(0)
                    end
                    showLines = true
                end
                if dollLayer then
                    if showLines then
                        dollLayer:setX(T.px(TAB_STRIP_W))
                        dollLayer:setY(win:getBodyY())
                        dollLayer:setWidth(math.floor(effectiveW))
                        dollLayer:setHeight(win:getHeight() - win:getBodyY())
                    end
                    if dollLayer:isVisible() ~= showLines then dollLayer:setVisible(showLines) end
                end

                -- must set BOTH Lua and Java visibility (the model's Java object keeps its own)
                model:setVisible(showAvatar)
                model.javaObject:setVisible(showAvatar)
            end
        end

        -- The Equip tab's item card hides every frame here; the Equip tab's own draw (below,
        -- same frame) shows it again when it is in card mode. Hidden by the Equip tab
        -- alone, it stayed over the next tab after a switch, catching clicks.
        if self._equipCard and self._equipCard:isVisible() then self._equipCard:setVisible(false) end

        -- Draw drawer background + content (in mc mode, only draw if item card is visible)
        local drawDrawer = effectiveW > 0 and (not mcActive or win._drawerMode == "item" or win._drawerMode == "tab")
        if drawDrawer then
            local dh = self:getHeight()
            -- Always stencil-clip drawer content to prevent child overflow (dropdowns, etc.)
            self:setStencilRect(0, 0, effectiveW, dh)

            -- Drawer background fill (theme-aware tonal separation)
            local db = T.drawerBg
            self:drawRect(0, 0, effectiveW, dh, db.a, db.r, db.g, db.b)

            -- (the card's background is the item drawer overlay's)

            -- Tab content (when drawer shows a tab, not an item)
            if win._drawerMode == "tab" and win._activeTab then
                local renderer = TAB_RENDERERS[win._activeTab]
                if renderer then
                    -- An open item card lies over the tab's right part: the tab draws
                    -- only what the card leaves showing (setTabCover), so the see-through
                    -- card is one surface over the world, not over a second layer of UI
                    local coverX = (win._drawerItem ~= nil) and math.max(0, targetW - T.px(ITEM_CARD_W)) or nil
                    if coverX and coverX < effectiveW then
                        self:clearStencilRect()
                        self:setStencilRect(0, 0, coverX, dh)
                        setTabCover(self, coverX)
                    else
                        coverX = nil
                    end
                    -- (a tab that throws must not repeat its error every frame or leave its own clip
                    -- set: log once, put the drawer's clip back, draw on)
                    -- (as in the World window: under a card every clear of any tab leaves one clip on,
                    -- since coverClear sets the card's cut again, and a tab may leave one of its own.
                    -- The inventory list's own clear (content._onPrerender) took off one, no more, so a
                    -- tab with two clips under a card, Journal > Recipes with a recipe picked, hid the
                    -- inventory list and all drawn after it. Whatever is left on comes off here; a
                    -- level tab with no card clears nothing.)
                    local clipsBefore = self._zedStencilN or 0   -- (the count ZeD_Panel keeps)
                    self._coverClears = 0
                    local okR, errR = pcall(renderer, self, win, 0, 0, targetW, dh)
                    if coverX then setTabCover(self, nil) end
                    -- (the tab's own leftovers, by the count, and coverClear's, which the count misses)
                    for _ = 1, (self._zedStencilN or 0) - clipsBefore + self._coverClears do self:clearStencilRect() end
                    if not okR then
                        self:clearStencilRect()
                        self:setStencilRect(0, 0, effectiveW, dh)
                        ZeD.logOnce("tab " .. tostring(win._activeTab), errR)
                    end
                else
                    -- (no tab drawer: the Loot view. Nothing is drawn; the drawer becomes what is left in it)
                    lootDrawerFallback(win)
                end
            end

            self:clearStencilRect()
        end
    end

    -- Drawer mouse handlers
    drawer.onMouseMove = function(self, dx, dy)
        ISPanel.onMouseMove(self, dx, dy)
        local T = ZeD.T
        -- Equipment row drag (a press on a worn item that has moved)
        if ZeD.EquipmentTab.dragMove(win, self) then return true end
        -- Equipment column drag update
        if win._equipColDrag then
            local cd = win._equipColDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            if not win._equipColWidths then
                win._equipColWidths = ZeD.EquipmentTab.getDefaultColWidths(ZeD.T.scale or 1)
            end
            win._equipColWidths[cd.col] = newW
            return true
        end
        -- Health figure hover (only when figure expanded)
        if win._activeTab == "health" and win._healthBodyFigure and win._healthFigureExpanded then
            local mx, my = self:getMouseX(), self:getMouseY()
            local hitPart = win._healthBodyFigure:hitTestAt(mx, my)
            win._healthHoveredPart = hitPart
        end
        -- Thermal figure hover (only when figure expanded)
        if win._activeTab == "thermal" and win._thermalBodyFigure and win._thermalFigureExpanded then
            local mx, my = self:getMouseX(), self:getMouseY()
            local hitPart = win._thermalBodyFigure:hitTestAt(mx, my)
            win._thermalHoveredPart = hitPart
        end
        -- Equipment defense figure hover
        if win._activeTab == "equip" and win._equipDefBodyFigure and not win._equipSelected then
            local mx, my = self:getMouseX(), self:getMouseY()
            local hitPart = win._equipDefBodyFigure:hitTestAt(mx, my)
            win._equipDefHoveredPart = hitPart
        end
        -- Scroll drag
        local scroll = getActiveScroll(win)
        if scroll and scroll.dragging then
            scroll:handleMouseMove(self:getMouseY() - scroll.y)
        end
    end

    drawer.onMouseMoveOutside = function(self, dx, dy)
        ISPanel.onMouseMoveOutside(self, dx, dy)
        local T = ZeD.T
        -- Equipment row drag continues outside the panel (the drawer captures the mouse)
        if ZeD.EquipmentTab.dragMove(win, self) then return true end
        -- Equipment column drag continues outside panel
        if win._equipColDrag then
            local cd = win._equipColDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            if not win._equipColWidths then
                win._equipColWidths = ZeD.EquipmentTab.getDefaultColWidths(ZeD.T.scale or 1)
            end
            win._equipColWidths[cd.col] = newW
            return true
        end
        if win._activeTab == "health" then
            win._healthHoveredPart = nil
        end
        if win._activeTab == "thermal" then
            win._thermalHoveredPart = nil
        end
        if win._activeTab == "equip" then
            win._equipDefHoveredPart = nil
        end
        local scroll = getActiveScroll(win)
        if scroll and scroll.dragging then
            scroll:handleMouseMove(self:getMouseY() - scroll.y)
        end
    end

    -- Scroll interaction for tab content
    -- Uses getActiveScroll() to dispatch to the correct tab's scroll state
    drawer.onMouseWheel = function(self, del)
        if win._drawerMode == "tab" then
            -- an open pop-up list (Health's exercises, Thermal's views) holds the wheel
            if (win._activeTab == "health" and win._healthMenuOpen) or (win._activeTab == "thermal" and win._thermalMenuOpen) then
                return true
            end
            -- a two-way radio's face: the wheel turns the knob under it (else its body scrolls)
            if win._activeTab == "radio" and ZeD.RadioTab.onWheel(win, del, self:getMouseX(), self:getMouseY()) then return true end
            -- Journal Recipes sub-tab: delegate to CraftingCore scroll
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 4 then
                local mx = self:getMouseX()
                local my = self:getMouseY()
                ZeD.JournalTab.onRecipeMouseWheel(win, del, mx, my)
                return true
            end
            local scroll = getActiveScroll(win)
            if scroll and scroll.visible then
                scroll:handleMouseWheel(del)
            end
        end
        return true
    end

    drawer.onMouseDown = function(self, x, y)
        if win._drawerMode == "tab" then
            -- Radio tab routing — delegate to RadioTab.onClick, which
            -- hit-tests the chassis zones stamped during render.
            if win._activeTab == "radio" then
                ZeD.RadioTab.onClick(win, x, y)
                return true
            end
            if ZeD_CharacterWindow.extClick(win, x, y) then return true end
            -- Skills and Equipment: the Find field's clear box, the empty result's Clear
            if ZeD.TabFind and ZeD.TabFind.onClick(win, x, y) then return true end
            -- Skills: a key a mod's head block stamped (ZeD.SkillsTab.stampStop)
            if win._activeTab == "skills" and ZeD.SkillsTab.onClick(win, x, y) then return true end
            -- Identity: the Hair and beard section (ZeD_HairBeard.lua) and its strip
            if win._activeTab == "identity" and ZeD.IdentityTab.onClick and ZeD.IdentityTab.onClick(win, x, y) then return true end
            -- Equipment tab click routing
            if win._activeTab == "equip" then
                -- the loadouts' bar and to-do (ZeD_EquipLoadout); the to-do takes every press
                if ZeD.EquipLoadout and ZeD.EquipLoadout.onClick(win, x, y) then return true end
                -- The List | Doll toggle, and a doll card's layer strip (EquipDoll.lua)
                if ZeD.EquipDoll and ZeD.EquipDoll.onClick(win, x, y) then return true end
                -- Card mode: back button
                if win._equipSelected and win._equipBackZone then
                    local bz = win._equipBackZone
                    if x >= bz.x and x <= bz.x + bz.w and y >= bz.y and y <= bz.y + bz.h then
                        win._equipSelected = nil
                        win._gpFocusedEquipSlot = nil  -- reseed to disclosure
                        return true
                    end
                end
                -- Card mode: action buttons
                if win._equipSelected and win._equipActionZones then
                    for _, zone in ipairs(win._equipActionZones) do
                        if x >= zone.x and x <= zone.x + zone.w
                           and y >= zone.y and y <= zone.y + zone.h then
                            -- Find the selected slot
                            local selSlot = nil
                            if win._equipCache then
                                for _, g in ipairs(win._equipCache.groups) do
                                    for _, s in ipairs(g.slots) do
                                        if s.type == win._equipSelected then selSlot = s; break end
                                    end
                                    if selSlot then break end
                                end
                            end
                            if selSlot then
                                ZeD.EquipmentTab._handleAction(win, zone.id, selSlot)
                            end
                            return true
                        end
                    end
                end
                -- Card mode: detail-zone structural docks (repair / remove patch)
                if win._equipSelected and win._equipDockZones and ZeD.ItemDetail then
                    for _, dz in ipairs(win._equipDockZones) do
                        if x >= dz.x and x <= dz.x + dz.w
                           and y >= dz.y and y <= dz.y + dz.h then
                            ZeD.ItemDetail.dispatchZoneAction(
                                win._playerObj, dz.item, dz.part, dz.action)
                            return true
                        end
                    end
                end
                -- List mode: column divider drag start
                if not win._equipSelected and win._equipDivZones then
                    for _, dz in ipairs(win._equipDivZones) do
                        if x >= dz.x and x < dz.x + dz.w and y >= dz.y and y < dz.y + dz.h then
                            local cw = win._equipColWidths
                            if not cw then
                                cw = ZeD.EquipmentTab.getDefaultColWidths(ZeD.T.scale or 1)
                                win._equipColWidths = cw
                            end
                            win._equipColDrag = {
                                col    = dz.col,
                                startX = getMouseX(),
                                startW = cw[dz.col],
                            }
                            self:setCapture(true)
                            return true
                        end
                    end
                end
                -- List mode: "Equipped" disclosure header toggle (controls
                -- the slot list visibility; defense body is always shown).
                if not win._equipSelected and win._equipDefenseZone then
                    local dz = win._equipDefenseZone
                    if x >= dz.x and x <= dz.x + dz.w
                       and y >= dz.y and y <= dz.y + dz.h then
                        win._equipListExpanded = not win._equipListExpanded
                        -- The per-frame refresh block owns zone focusability
                        -- + element rebuild; no direct setZoneFocusable call.
                        return true
                    end
                end
                -- List mode: group header toggles
                if not win._equipSelected and win._equipGroupZones then
                    for _, zone in ipairs(win._equipGroupZones) do
                        if x >= zone.x and x <= zone.x + zone.w
                           and y >= zone.y and y <= zone.y + zone.h then
                            win._equipExpanded[zone.id] = not win._equipExpanded[zone.id]
                            return true
                        end
                    end
                end
                -- List mode: a belt row's button (DETACH, PUT BACK, or
                -- ATTACH's list). Pressed here, run on release over the same
                -- button: a menu opened on the press would close on the
                -- release (the menu closes on any click outside it).
                if not win._equipSelected and win._equipBeltZones then
                    for _, zone in ipairs(win._equipBeltZones) do
                        local b = zone.btn
                        if b and x >= b.x and x <= b.x + b.w
                           and y >= b.y and y <= b.y + b.h then
                            win._beltPress = { i = zone.i, action = zone.action }
                            return true
                        end
                    end
                end
                -- List mode and doll: a filled slot's press. Released in place it
                -- selects (the item card); moved off, it is the inventory's drag
                -- (EquipmentTab.pressSlot and its siblings below).
                if ZeD.EquipmentTab.pressSlot(win, self, x, y) then return true end
            end
            -- Journal header: the Page box opens its list; the open list takes every click
            -- (the pages were once a sub-tab strip, hence _journalSubTab)
            if win._activeTab == "journal" and ZeD.JournalTab and ZeD.JournalTab.onHeaderClick
               and ZeD.JournalTab.onHeaderClick(win, x, y) then
                return true
            end
            -- (No map clicks here: the Maps page — disclosure chevron, icon tools,
            -- color swatches, pan / drag — is the World window's.)
            -- Journal tags: a pick under the write box ticks, a tag on an entry searches for it
            if win._activeTab == "journal" and ZeD.JournalTab.onBodyClick and ZeD.JournalTab.onBodyClick(win, x, y) then
                return true
            end
            -- Journal group collapse/expand (only in Journal sub-tab)
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 1 and win._journalGroupZones then
                for _, zone in ipairs(win._journalGroupZones) do
                    if x >= zone.x and x <= zone.x + zone.w
                       and y >= zone.y and y <= zone.y + zone.h then
                        win._journalGroupCollapsed[zone.id] = not win._journalGroupCollapsed[zone.id]
                        win._journalCache = nil
                        return true
                    end
                end
            end
            -- Journal entry delete (only in Journal sub-tab)
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 1 and win._journalDeleteZones then
                for _, zone in ipairs(win._journalDeleteZones) do
                    if x >= zone.x and x <= zone.x + zone.w
                       and y >= zone.y and y <= zone.y + zone.h then
                        -- asked about first (the Journal tab's question band), when the tab has one
                        if askJournalDelete(win, zone.entryIdx) then return true end
                        local md = win._playerObj:getModData()
                        if md and md.ZeD_Journal and md.ZeD_Journal.entries then
                            table.remove(md.ZeD_Journal.entries, zone.entryIdx)
                        end
                        win._journalCache = nil
                        return true
                    end
                end
            end
            -- Journal kills expand/collapse (only in Journal sub-tab)
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 1 and win._killsRowH > 0 then
                if y >= win._killsRowY and y <= win._killsRowY + win._killsRowH then
                    win._killsExpanded = not win._killsExpanded
                    win._journalCache = nil  -- force layout recalc
                    return true
                end
            end
            -- Notebooks / Papers / the log box's Into (ZeD_JournalReaders stamps the zones)
            if win._activeTab == "journal" and ZeD.JournalReaders and ZeD.JournalReaders.onClick(win, x, y) then
                return true
            end
            -- Loadouts (ZeD_JournalLists stamps the zones)
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 5 and ZeD.JournalLists
               and ZeD.JournalLists.onClick(win, x, y) then
                return true
            end
            -- Journal Recipes sub-tab: delegate to CraftingCore via JournalTab
            if win._activeTab == "journal" and (win._journalSubTab or 1) == 4 then
                if ZeD.JournalTab.onRecipeClick(win, x, y) then
                    return true
                end
            end
            -- Health footer band: the exercise pop-up (an open list takes every press, so this
            -- comes before the rest), the session time's - / + and Start (HealthTab.onClick)
            if win._activeTab == "health" and ZeD.HealthTab.onClick(win, x, y) then
                return true
            end
            -- Health figure disclosure toggle
            if win._activeTab == "health" and win._healthFigureZone then
                local fz = win._healthFigureZone
                if x >= fz.x and x <= fz.x + fz.w
                   and y >= fz.y and y <= fz.y + fz.h then
                    win._healthFigureExpanded = not win._healthFigureExpanded
                    return true
                end
            end
            -- Thermal footer band: the View pop-up (an open list takes every press, so this
            -- comes before the rest) (ThermalTab.onClick)
            if win._activeTab == "thermal" and ZeD.ThermalTab.onClick(win, x, y) then
                return true
            end
            -- Thermal figure disclosure toggle
            if win._activeTab == "thermal" and win._thermalFigureZone then
                local fz = win._thermalFigureZone
                if x >= fz.x and x <= fz.x + fz.w
                   and y >= fz.y and y <= fz.y + fz.h then
                    win._thermalFigureExpanded = not win._thermalFigureExpanded
                    return true
                end
            end
            -- Skills grid disclosure toggle
            if win._activeTab == "skills" and win._skillsGridZone then
                local fz = win._skillsGridZone
                if x >= fz.x and x <= fz.x + fz.w
                   and y >= fz.y and y <= fz.y + fz.h then
                    win._skillsGridExpanded = not win._skillsGridExpanded
                    win._skillsCache = nil
                    return true
                end
            end
            -- Identity tab-header disclosure toggle. Matches the pad's A on
            -- it — click toggles _identityPhotoExpanded and resets custom
            -- zoom + scroll, same behavior as the photo click on
            -- identityModel.onMouseUp.
            if win._activeTab == "identity" and win._identityFigureZone then
                local fz = win._identityFigureZone
                if x >= fz.x and x <= fz.x + fz.w
                   and y >= fz.y and y <= fz.y + fz.h then
                    win._identityPhotoExpanded = not win._identityPhotoExpanded
                    win._identityCustomZoom    = 0
                    if win._identityScroll then win._identityScroll:setScrollPos(0) end
                    return true
                end
            end
            -- (a plain click on a skill row does not pin it: the row's right-click menu does)
            -- Training materials expand/collapse click detection
            if win._activeTab == "skills" and win._trainingGroupZones then
                for _, zone in ipairs(win._trainingGroupZones) do
                    if x >= zone.x and x <= zone.x + zone.w
                       and y >= zone.y and y <= zone.y + zone.h then
                        win._trainingExpanded = win._trainingExpanded or {}
                        win._trainingExpanded[zone.id] = not win._trainingExpanded[zone.id]
                        win._skillsCache = nil  -- force scroll height recalc
                        return true
                    end
                end
            end
            local scroll = getActiveScroll(win)
            if scroll and scroll.visible then
                if x >= scroll.x then
                    scroll:handleMouseDown(y - scroll.y)
                    return true
                end
            end
        end
        return true
    end

    drawer.onMouseUp = function(self, x, y)
        -- A belt row's button: run its verb if released over the button pressed
        local pr = win._beltPress
        if pr then
            win._beltPress = nil
            for _, zone in ipairs(win._equipBeltZones or {}) do
                local b = zone.btn
                if zone.i == pr.i and zone.action == pr.action and b
                   and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
                    ZeD.EquipmentTab.beltAction(win, zone,
                        self:getAbsoluteX() + b.x + math.floor(b.w / 2),
                        self:getAbsoluteY() + b.y)
                end
            end
            return true
        end
        -- Equipment row drag: the drop, or the plain click that never moved
        if ZeD.EquipmentTab.dragRelease(win, self) then return true end
        -- Equipment column drag release
        if win._equipColDrag then
            win._equipColDrag = nil
            self:setCapture(false)
            return true
        end
        local scroll = getActiveScroll(win)
        if scroll then scroll:handleMouseUp() end
        return true
    end

    -- (onMouseMove and onMouseMoveOutside defined above with thermal hover + scroll drag)

    drawer.onMouseUpOutside = function(self, x, y)
        win._beltPress = nil
        -- Equipment row drag released outside the drawer: the drop
        if ZeD.EquipmentTab.dragRelease(win, self) then return true end
        -- Equipment column drag release (outside panel)
        if win._equipColDrag then
            win._equipColDrag = nil
            self:setCapture(false)
            return true
        end
        local scroll = getActiveScroll(win)
        if scroll then scroll:handleMouseUp() end
        return true
    end

    -- (The map's right-click handlers — pin toggle, annotation menu — are the
    -- World window's, with the Maps page.)
    drawer.onRightMouseDown = function(self, x, y)
        -- a right press calls off an Equip row's drag (as it does the lists')
        ZeD.EquipmentTab.dragCancel(win, self)
        -- a two-way radio's control: its second meaning (MEM names, a knob turns down)
        if win._drawerMode == "tab" and win._activeTab == "radio" then ZeD.RadioTab.onRightClick(win, x, y) end
        return true
    end

    -- Right-click in the drawer: a skill row's menu, the Loadouts page's,
    -- Health's treatment menu, a belt row's menu, and on the Equipment list
    -- the vanilla context menu (parity with inv lists): it walks
    -- _equipSlotZones (stamped by EquipmentTab.render in list mode) and
    -- spawns the same ZeD-skinned ISInventoryPaneContextMenu.createMenu the
    -- inventory rows use — Drop / Wear / Read / Repair / etc. on the
    -- equipped item.
    drawer.onRightMouseUp = function(self, x, y)
        -- a skill row: its menu, Pin to title bar (ZeD_Pins)
        if win._activeTab == "skills" and win._drawerMode == "tab" and win._skillRowZones then
            for _, zone in ipairs(win._skillRowZones) do
                if x >= zone.x and x <= zone.x + zone.w and y >= zone.y and y <= zone.y + zone.h then
                    skillRowMenu(win, zone.name, self:getAbsoluteX() + x, self:getAbsoluteY() + y)
                    return true
                end
            end
        end
        -- the Journal's Loadouts page: a line's Remove, a list's Rename / Delete
        if win._activeTab == "journal" and win._drawerMode == "tab" and (win._journalSubTab or 1) == 5
           and ZeD.JournalLists and ZeD.JournalLists.onRightClick(win, x, y) then
            return true
        end
        -- Health: the body figure or an injury row opens vanilla's treatment menu
        if win._activeTab == "health" and win._drawerMode == "tab" then
            _healthTreatAt(win, self, x, y)
            return true
        end
        if win._activeTab == "equip" and win._drawerMode == "tab"
           and not win._equipSelected and win._equipBeltZones and ZeD.Belt then
            for _, zone in ipairs(win._equipBeltZones) do
                if x >= zone.x and x <= zone.x + zone.w
                   and y >= zone.y and y <= zone.y + zone.h then
                    ZeD.Belt.rightMenu(ZeD.playerNumOf(win), zone.i)
                    return true
                end
            end
        end
        if win._activeTab == "equip" and win._drawerMode == "tab"
           and not win._equipSelected and win._equipSlotZones then
            for _, zone in ipairs(win._equipSlotZones) do
                if zone.item
                   and x >= zone.x and x <= zone.x + zone.w
                   and y >= zone.y and y <= zone.y + zone.h then
                    local playerObj = getSpecificPlayer(ZeD.playerNumOf(win))
                    if playerObj then
                        local pNum = playerObj:getPlayerNum()
                        local inv  = playerObj:getInventory()
                        local isInInv = inv:isInCharacterInventory(playerObj)
                        ISInventoryPaneContextMenu.createMenu(
                            pNum, isInInv, { zone.item },
                            self:getAbsoluteX() + x, self:getAbsoluteY() + y
                        )
                    end
                    return true
                end
            end
        end
        return true
    end

    -- ----------------------------------------------------------------
    -- SELECTION → DRAWER HELPER (full state machine with snap-back)
    -- ----------------------------------------------------------------
    local function updateDrawer(contentPanel)
        local T = ZeD.T
        local prevMode = win._drawerMode
        local prevItem = win._drawerItem   -- card-visibility snapshot (World parity)
        local sel = contentPanel._selectedItems
        local count = 0
        local singleItem = nil
        for item, _ in pairs(sel) do
            count = count + 1
            singleItem = item
            if count > 1 then break end
        end
        if count == 0 then contentPanel._padMarks = nil end   -- (the marks gone, their rule with them)
        -- the controller's marks hide the card even at one, as the mouse's many do
        if count == 1 and not contentPanel._padMarks then
            -- Single item selected: show item card (overlay if tab active)
            if singleItem ~= win._drawerItem then
                win._itemCard:setItem(singleItem)
            end
            win._drawerItem = singleItem
            -- Wire the ItemCard organism's sourceContext so its back-bar
            -- verb cluster resolves correctly per source.
            -- "equipped" → UNEQUIP/DROP; "inventory" → EQUIP/EAT/READ/USE +DROP;
            -- "container" → TAKE/EQUIP. Equipped check first since that wins
            -- regardless of which container the item lives in.
            -- win._activeContainer is an INDEX into win._containers,
            -- NOT a container reference. Resolve via _containers[idx].isMain
            -- (player's primary inventory entry).
            do
                local cntEntry = win._containers
                    and win._containers[win._activeContainer or 1]
                local isEq = singleItem.isEquipped
                    and (function() local ok, v = pcall(singleItem.isEquipped, singleItem); return ok and v end)() or false
                if isEq then
                    win._itemCard.sourceContext = "equipped"
                elseif cntEntry and cntEntry.isMain then
                    win._itemCard.sourceContext = "inventory"
                else
                    win._itemCard.sourceContext = "container"
                end
            end
            if win._drawerMode ~= "tab" then
                if not win._drawerOpen then
                    win._preDrawerW = win:getWidth()
                end
                win._drawerMode = "item"
                -- Snap to avoid tiny-width animation hang
                if (win._drawerEffW or 0) < T.px(ITEM_CARD_W) then
                    win._drawerEffW = T.px(ITEM_CARD_W)
                end
            end
            win._drawerOpen = true
        else
            -- No item (or multi-select): hide card, restore mode
            win._drawerItem = nil
            if win._drawerMode == "item" then
                if #(win._mcSelected or {}) > 0 then
                    win._drawerMode = nil
                    -- _drawerOpen stays true for MC columns
                else
                    win._drawerMode = nil
                    win._drawerOpen = false
                end
            end
            -- If drawerMode == "tab", don't close — deselection doesn't affect tab panels
        end

        -- If we just transitioned OUT of "item" mode and focus was on
        -- charItemCard, snap ring focus back to charMainInv. Without this,
        -- setZoneFocusable(false) in the per-frame refresh would auto-rotate
        -- _focusIdx FORWARD to charContainerStrip — not what the user expects
        -- after closing the card from inventory.
        -- Also when a card over a tab closes (its mode stays
        -- "tab"): B on the card goes back to the row (World window parity)
        if ((prevMode == "item" and win._drawerMode ~= "item")
            or (prevItem ~= nil and win._drawerItem == nil)) and win._focusRing then
            local cardIdx, invIdx
            for i, z in ipairs(win._focusRing) do
                if z.zone == "charItemCard" then cardIdx = i
                elseif z.zone == "charMainInv"  then invIdx  = i end
            end
            if cardIdx and invIdx and win._focusIdx == cardIdx then
                win._focusIdx = invIdx
            end
        end
    end

    -- Expose updateDrawer so gamepad bindings (A on inv row → open card)
    -- can trigger drawer state changes via the same path mouse-click uses.
    win._updateDrawer = updateDrawer

    -- No D-pad direction wrappers here. Under flat free-nav, D-pad is
    -- pure spatial cone-nav across all focusable zones in the focused window:
    -- the base ZeD_Window:onJoypadDir* methods dispatch directly to
    -- FocusManager. What a wrapper would do lives on the elements:
    --   * Disclosure expand/collapse → A (onActivate toggles, mouse parity)
    --   * Stack expand/collapse      → A (onActivate on stack chevron toggles)
    --   * Item card open             → A on inv row (selects item, drawer opens)
    --   * Item card close            → B (onCancel closes drawer)
    --   * Card U/D                   → onDpadDir on the card's elements (ZeD_ItemCard:gpDpad)
    --   * GridScroll U/D scrolling   → onDpadDir on the gridScroll pseudo-focusable
    --   * Maps cursor / animals zone-cursor → onDpadDir (WorldWindow elements)

    -- Content panel — right of tab strip + drawer (the drawer's prerender sets its x and width)
    content = ZeD_Panel:new(T.px(TAB_STRIP_W), bodyY, T.px(win._baseInvW), bodyH)
    content._zedLabel = "char content"   -- its own name in console.txt and safe mode's watchdog
    content.anchorRight = false  -- drawer prerender controls position/width, not ISPanel auto-resize
    content:initialise()
    win:addChild(content)
    win._contentPanel = content
    -- Expose the content panel to the gamepad focus callbacks set earlier
    -- in toggle(). Closures look up `win._mainContent` at fire time, so it's
    -- fine that this assignment happens after the ring was built.
    win._mainContent = content

    -- Container strip — right edge, a vertical list
    containerStrip = ZeD_Panel:new(T.px(TAB_STRIP_W) + T.px(win._baseInvW), bodyY, T.px(CONTAINER_STRIP_W), bodyH)
    containerStrip._zedLabel = "char container strip"   -- its own name in console.txt and safe mode's watchdog
    containerStrip.anchorRight = false
    containerStrip:initialise()
    win:addChild(containerStrip)

    -- Identity avatar: after containerStrip (above drawer content), before itemDrawer
    win:addChild(identityModel)
    -- the portrait studio's camera button, after the figure so it lies over it and takes its own press (punch list
    -- 145: ZeD_Studio.lua); placed by _placeIdentityModel, shown with the ID photo
    if ZeD.Studio and ZeD.Studio.newCamButton then
        local cam = ZeD.Studio.newCamButton(win)
        win:addChild(cam)
        win._studioBtn = cam
    end
    -- The Equip doll's leader lines: above the model so their dots land on the
    -- body; mouse events pass through to the drawer (EquipDoll.newLineLayer)
    if ZeD.EquipDoll then
        win._equipDollLayer = ZeD.EquipDoll.newLineLayer(win)
        win:addChild(win._equipDollLayer)
    end

    -- The item drawer overlay: added after these so the card renders on top of drawer + content
    win:addChild(itemDrawer)

    -- The tab hover hint: a click-through layer above everything (ZeD.Atoms.newHintLayer)
    win._tabHintLayer = ZeD.Atoms.newHintLayer(win, "_tabHintCand")
    win._tabHintLayer:setWidth(win:getWidth())
    win._tabHintLayer:setHeight(win:getHeight())
    win:addChild(win._tabHintLayer)

    win._stripScrollOffset = 0
    win._stripDrag = nil
    win._stripListEntries = {}
    win._stripBtnMidpoints = {}

    win._containerStrip = containerStrip
    containerStrip._onPrerender = function(self) drawContainerStrip(self, win, content) end

    containerStrip.onMouseDown = function(self, x, y)
        local zone = self:hitZoneAt(x, y)
        if not zone then return true end
        local zid = zone.id
        local T = ZeD.T

        -- Scroll arrows
        if zid == "strip_scroll_up" then
            win._stripScrollOffset = (win._stripScrollOffset or 0) - T.px(CONTAINER_BTN_SZ)
            return true
        elseif zid == "strip_scroll_down" then
            win._stripScrollOffset = (win._stripScrollOffset or 0) + T.px(CONTAINER_BTN_SZ)
            return true
        end

        -- Main container toggle
        if zid == "main_toggle" then
            if win._activeTab == "loot" then
                -- Always toggle MAIN (container idx 1), regardless of
                -- _activeContainer. Zone 1 is permanently pinned to main —
                -- clicking it always controls main visibility in MC mode.
                mcToggleContainer(win, content, 1)
            else
                -- Non-loot: toggle inventory drawer showing on-person
                local currentView = win._viewedContainer or win._activeContainer
                if currentView == win._activeContainer and win._invDrawerOpen then
                    win._invDrawerOpen = false
                    local drawerW = math.floor(win._drawerEffW or 0)
                    local snapW = T.px(TAB_STRIP_W) + drawerW + T.px(CONTAINER_STRIP_W)
                    win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                    win:setWidth(snapW)
                    local snapX = win._anchorRightEdge - snapW
                    win:setX(snapX)
                    win._lastSetX = snapX
                else
                    win._viewedContainer = nil  -- show main
                    win._activeContainer = 1
                    win._mainVisible = true
                    win._invDrawerOpen = true
                    local drawerW = math.floor(win._drawerEffW or 0)
                    local baseInv = T.px(win._baseInvW or 372)
                    local snapW = T.px(TAB_STRIP_W) + drawerW + baseInv + T.px(CONTAINER_STRIP_W)
                    local maxW = win._maxWinW or math.floor(ZeD.screenOf(win) * 0.5)
                    snapW = math.min(snapW, maxW)
                    win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                    win:setWidth(snapW)
                    local snapX = win._anchorRightEdge - snapW
                    win:setX(snapX)
                    win._lastSetX = snapX
                    content._inventory = win._containers[win._activeContainer].inventory
                    content._selectedItems = {}
                    content._lastClickedItem = nil
                end
            end
            return true
        end

        -- Sort mode cycle: dist → wt → type → dist
        if zid == "wt_sort" then
            local cycle = { dist = "wt", wt = "type", type = "dist" }
            win._containerSortMode = cycle[win._containerSortMode or "dist"] or "wt"
            local order = {}
            for i = 1, #win._containers do order[i] = i end
            win._containerOrder = order
            return true
        end

        -- Container button → start pending drag (click resolved on mouseUp)
        if type(zid) == "string" and zid:sub(1, 4) == "cnt:" then
            local idx = tonumber(zid:sub(5))
            if idx and win._containers[idx] then
                -- Find display position in list entries
                local displayIdx = 1
                for li, ci in ipairs(win._stripListEntries or {}) do
                    if ci == idx then displayIdx = li; break end
                end
                win._stripDrag = {
                    containerIdx = idx,
                    displayIdx = displayIdx,
                    startY = getMouseY(),
                    active = false,
                    insertIdx = nil,
                }
            end
            return true
        end
        return true
    end

    containerStrip.onMouseUp = function(self, x, y)
        local T = ZeD.T
        local drag = win._stripDrag
        if drag then
            if drag.active and drag.insertIdx then
                -- Reorder: move in _containerOrder
                -- Map list display indices back to order indices (the list leaves out main)
                local order = win._containerOrder or {}
                -- Find the order index of the dragged container
                local srcOrderIdx, dstOrderIdx
                local listEntries = win._stripListEntries or {}
                local srcCI = drag.containerIdx
                for oi, ci in ipairs(order) do
                    if ci == srcCI then srcOrderIdx = oi; break end
                end
                if srcOrderIdx then
                    -- Compute destination order index from insertIdx in list
                    local insertIdx = drag.insertIdx
                    -- The list entry at insertIdx position, or end of list
                    local targetCI
                    if insertIdx <= #listEntries then
                        targetCI = listEntries[insertIdx]
                    end
                    if targetCI then
                        for oi, ci in ipairs(order) do
                            if ci == targetCI then dstOrderIdx = oi; break end
                        end
                    else
                        dstOrderIdx = #order + 1
                    end
                    if dstOrderIdx and dstOrderIdx ~= srcOrderIdx then
                        local val = table.remove(order, srcOrderIdx)
                        if dstOrderIdx > srcOrderIdx then dstOrderIdx = dstOrderIdx - 1 end
                        table.insert(order, dstOrderIdx, val)
                        win._containerSortByWT = false
                    end
                end
            else
                -- No drag threshold → click to select/toggle container
                local idx = drag.containerIdx
                if idx and win._containers[idx] then
                    if win._activeTab == "loot" then
                        -- Loot tab: MC toggle (multi-column)
                        mcToggleContainer(win, content, idx)
                    else
                        -- Other tabs: switch viewed container or toggle inventory
                        local currentView = win._viewedContainer or win._activeContainer
                        if idx == currentView and win._invDrawerOpen then
                            -- Same container: close inventory (snap)
                            win._invDrawerOpen = false
                            local drawerW = math.floor(win._drawerEffW or 0)
                            local snapW = T.px(TAB_STRIP_W) + drawerW + T.px(CONTAINER_STRIP_W)
                            win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                    win:setWidth(snapW)
                            local snapX = win._anchorRightEdge - snapW
                            win:setX(snapX)
                            win._lastSetX = snapX
                        elseif not win._invDrawerOpen then
                            -- Inventory closed: open showing this container (snap)
                            win._viewedContainer = idx
                            win._invDrawerOpen = true
                            local drawerW = math.floor(win._drawerEffW or 0)
                            local baseInv = T.px(win._baseInvW or 372)
                            local snapW = T.px(TAB_STRIP_W) + drawerW + baseInv + T.px(CONTAINER_STRIP_W)
                            local maxW = win._maxWinW or math.floor(ZeD.screenOf(win) * 0.5)
                            snapW = math.min(snapW, maxW)
                            win.minimumWidth = math.min(snapW, win.minimumWidth or snapW)
                    win:setWidth(snapW)
                            local snapX = win._anchorRightEdge - snapW
                            win:setX(snapX)
                            win._lastSetX = snapX
                        else
                            -- Different container: switch to it
                            win._viewedContainer = idx
                        end
                        if win._invDrawerOpen then
                            content._inventory = win._containers[win._viewedContainer or win._activeContainer].inventory
                        end
                        content._selectedItems = {}
                        content._lastClickedItem = nil
                    end
                end
            end
            win._stripDrag = nil
            self:setCapture(false)
            return true
        end
        return true
    end

    containerStrip.onMouseMove = function(self, dx, dy)
        local T = ZeD.T
        local drag = win._stripDrag
        if not drag then return true end
        local screenY = getMouseY()
        if not drag.active then
            if math.abs(screenY - drag.startY) >= T.px(4) then
                -- Don't allow dragging main inventory
                if win._containers[drag.containerIdx] and win._containers[drag.containerIdx].isMain then
                    win._stripDrag = nil
                    return true
                end
                drag.active = true
                self:setCapture(true)
            end
        end
        if drag.active then
            local localY = self:getMouseY()
            local midpoints = win._stripBtnMidpoints or {}
            local insertIdx = #midpoints + 1
            for li, mid in ipairs(midpoints) do
                if localY < mid then
                    insertIdx = li
                    break
                end
            end
            drag.insertIdx = insertIdx
        end
        return true
    end

    containerStrip.onMouseMoveOutside = function(self, dx, dy)
        -- Continue drag tracking outside
        local drag = win._stripDrag
        if drag and drag.active then
            local localY = self:getMouseY()
            local midpoints = win._stripBtnMidpoints or {}
            local insertIdx = #midpoints + 1
            for li, mid in ipairs(midpoints) do
                if localY < mid then
                    insertIdx = li
                    break
                end
            end
            drag.insertIdx = insertIdx
        end
        return true
    end

    containerStrip.onMouseUpOutside = function(self, x, y)
        if win._stripDrag then
            win._stripDrag = nil
            self:setCapture(false)
        end
        return true
    end

    containerStrip.onMouseWheel = function(self, del)
        local T = ZeD.T
        local entries = win._stripListEntries or {}
        if #entries > 0 then
            win._stripScrollOffset = (win._stripScrollOffset or 0) + del * T.px(CONTAINER_BTN_SZ)
        end
        return true
    end

    -- Inventory data refs
    content._playerObj     = playerObj
    content._inventory     = playerObj:getInventory()
    content._selectedItems = {}
    content._lastClickedItem = nil
    content._flatItems     = {}

    -- Sort state
    content._sortCol = "name"
    content._sortAsc = true

    -- Column header Y offset: row 1 (T.stripH), so the column header sits in row 2 beside the strip's sort row
    -- (set again before each draw, so a new text size or UI scale moves it with the strips)
    content._hdrYOffset = T.stripH
    content._defaultHdrYOffset = T.stripH

    -- Container buttons (ContainerControls): the row at the bottom of the list
    content._ccSide = "char"
    content._ccWin  = win

    -- Collapse state
    content._collapsedGroups = {}

    -- Scrollbar state
    local ZeD_ScrollbarState = ZeD.Molecules.ScrollbarState
    content._scroll = ZeD_ScrollbarState:new()
    content._scroll.visible = true
    content._scroll.onScroll = function(pos) end

    -- Drag state
    local ZeD_DragState = ZeD.Molecules.DragState
    content._drag = ZeD_DragState:new()
    content._deferredSelect = nil

    -- Draw hooks — inventory always visible
    -- the selection box being drawn from empty space, over the rows of every column (punch list 146)
    content._onRender = function(self) if self._box and ZeD.BoxSelect then ZeD.BoxSelect.draw(self) end end
    content._onPrerender = function(self)
        -- Safety: clear any stencil leaked from drawer panel's tab renderer
        self:clearStencilRect()

        -- Suppress vanilla if another system re-showed it (not once safe mode has
        -- handed it back: this window may draw one last frame after a trip)
        -- (this window's own player's pages: split view)
        local vpn = win.playerNum or 0
        local vi = getPlayerInventory(vpn)
        local vl = getPlayerLoot(vpn)
        if vi and vi:getIsVisible() and not ZeD.Safe.on("windows") then vi:setVisible(false) end
        if vl and vl:getIsVisible() and not ZeD.Safe.on("windows") then vl:setVisible(false) end

        -- The card's item gone (eaten, dropped, moved to the world): the card closes, as a
        -- deselect would. Checked every 10 frames: the drawer only updates on a new
        -- selection, so without this the card and its live buttons outlived the item.
        self._goneTick = (self._goneTick or 0) + 1
        if self._goneTick >= 10 then
            self._goneTick = 0
            local di, p = win._drawerItem, self._playerObj
            if di and p then
                local okC, here = pcall(function()
                    local c = di:getContainer()
                    return c ~= nil and (c == p:getInventory() or c:isInCharacterInventory(p))
                end)
                if okC and not here then
                    if self._selectedItems then self._selectedItems[di] = nil end
                    updateDrawer(self)
                end
            end
        end

        -- Title bar stats: the pins, then weight / max. Health is the status pixel before the name
        -- (composeCharHealth, the window's own prerender).
        local inv = self._inventory
        -- (the character's own load over their own max, never the viewed bag's weight)
        local weight = self._playerObj:getInventory():getCapacityWeight()
        local maxWt = self._playerObj:getMaxWeight()
        win.titleStats = {}

        -- the pins (ZeD_Pins: skills, the book read, liquids, what is left, condition; leftmost). The mark is the
        -- pin's status, the words plain (a skill near its next level shown in red read as bad news)
        win._pinnedSkills = ZeD.Pins.skillNames(self._playerObj)
        local pinStats = ZeD.Pins.stats(self._playerObj)
        for _, st in ipairs(pinStats) do win.titleStats[#win.titleStats + 1] = st end

        -- Weight (rightmost): "5.8 / 28 kg", its unit kept so it never reads as bare numbers; no status mark
        win.titleStats[#win.titleStats + 1] = { text = ZeD.Atoms.loadText(weight, maxWt), noMark = true }

        local mcSel = win._mcSelected or {}
        -- Count visible MC columns
        local colCount = #mcSel + (win._mainVisible and 1 or 0)

        if #mcSel > 0 and colCount >= 2 then
            -- Multi-column MC: render side-by-side
            local colSel = {}
            for _, ci in ipairs(mcSel) do
                colSel[#colSel + 1] = ci
            end
            -- main column = containers[1] (see mcToggleContainer).
            if win._mainVisible then
                colSel[#colSel + 1] = 1
            end

            self._selectedContainers = colSel
            self._containers = win._containers
            self._barH = 0
            self._activeCol = math.min(self._activeCol or #colSel, #colSel)

            -- the title keeps the character's name; what the inventory side shows follows it
            win._titleSub = (#colSel == 1) and ZeD.tr("UI_ZeD_Char_ContainersOne", #colSel) or ZeD.tr("UI_ZeD_Char_ContainersMany", #colSel)
            self._ccEntry = nil

            self._defaultHdrYOffset = ZeD.T.stripH   -- (row 1, read fresh: punch list 178)
            r.renderMultiColumnContent(self)
            -- (after the columns drew: they now hold this frame's picks) the help line's own words,
            -- every shown column's things, and what is picked across them (InventoryPicked.lua)
            win._statusLine = ZeD.InventoryPicked.line(self, self._colStates, nil,
                "UI_ZeD_Char_ItemsOne", "UI_ZeD_Char_ItemsMany", win._playerObj)
        else
            -- Single container mode: determine which container to show
            local viewIdx
            if #mcSel > 0 and not win._mainVisible then
                -- Main hidden, 1 MC column: show that container
                viewIdx = mcSel[1]
            else
                viewIdx = win._viewedContainer or win._activeContainer
            end
            local cnt = win._containers[viewIdx]
            if cnt then
                -- the title keeps the character's name; a bag being viewed follows it
                win._titleSub = (not cnt.isMain) and cnt.name or nil
                local cInv = cnt.inventory
                local cWeight = cInv and round(cInv:getCapacityWeight(), 1) or 0
                local cMax = cInv and round(ZeD.InventoryRenderer.capacityOf(cInv, win._playerObj), 1) or 0
                -- (what the rows show is counted: worn and held things leave this list, and a mod's gate,
                -- ContainerGates.lua, lets only some show; its words stand for the weight, Immersive Searching's
                -- "Not searched" on a bag never searched)
                local cItems = cInv and ZeD.InventoryRenderer.shownCount(self, cInv, win._playerObj) or 0
                self._containerInfo = {
                    name    = cnt.name,
                    texture = cnt.texture,
                    stats   = ZeD.ContainerGates.status(cInv, win._playerObj) or ZeD.Atoms.loadText(cWeight, cMax),
                    count   = (cItems == 1) and ZeD.tr("UI_ZeD_Char_ItemsOne", cItems) or ZeD.tr("UI_ZeD_Char_ItemsMany", cItems),
                }
                self._inventory = cInv
                -- the help line's own words when the pointer is on nothing that has help: "48 items",
                -- or "3 of 48 picked | 4.2 kg" while rows are picked (InventoryPicked.lua). No weight
                -- at rest: the heading shows the container's, the title bar the character's load.
                win._statusLine = ZeD.InventoryPicked.line(self, nil, cItems,
                    "UI_ZeD_Char_ItemsOne", "UI_ZeD_Char_ItemsMany", win._playerObj)
            end
            self._ccEntry = cnt
            self._hdrYOffset = ZeD.T.stripH   -- (row 1, read fresh: punch list 178)
            r.renderItemList(self)
        end
        if ZeD.ContainerControls then
            local okF, eF = pcall(ZeD.ContainerControls.syncFocus, win, self)
            if not okF then ZeD.logOnce("ContainerControls focus", eF) end
        end

        -- the controller's stops (a function of its own: the drawer runs it too while this
        -- side does not draw, the tab drawer taking the whole window)
        content._focusRefresh(self)

        -- (the title is built in the window's prerender, composeCharTitle: this side
        -- does not draw while the tab drawer takes the whole window)
    end

    -- The Character window's tab stops, the per-frame refresh of the charTabContent zone (kept out of
    -- content._focusRefresh so the controller can ask for it between frames: win._focusFresh)
    content._tabStopsRefresh = function(self, Focus)
        if Focus and win._focusRing and (
                 win._activeTab == "equip"  or
                 win._activeTab == "health" or
                 win._activeTab == "thermal" or
                 win._activeTab == "skills" or
                 win._activeTab == "identity" or
                 win._activeTab == "journal" or
                 ZeD_CharacterWindow._extTabs[win._activeTab] ~= nil or
                 win._activeTab == "radio"  -- the radio's contextual chassis
                                            -- stamps its rect zones during render,
                                            -- so the tab-switch sync reads zero
                                            -- focusables; this catch-up picks
                                            -- them up on the next frame.
               ) then
            -- Per-frame refresh for NON-Loot tabs. The per-tab zone tables
            -- (_equipSlotZones, _healthBand, _thermalBand,
            -- _skillRowZones) are populated by the respective tab renderers
            -- each frame. _syncRingZonesToActiveTab fires on tab switch BEFORE
            -- the new tab's renderer has run, so it reads empty tables. This
            -- catch-up refresh runs AFTER the renderer populates the tables,
            -- syncing the ring zone to the live data. These are UI chrome
            -- elements keyed by static ID (slotType, band stop ids, skillName),
            -- so focus is kept by id (below). A dirty check (count, end ids,
            -- the last stop's place, the tab's scrollKey) keeps the rebuild
            -- cheap; where no id matches, setRingZoneElements without
            -- preserveIdx clamps the existing focusedElementIdx to the
            -- new array length so the gp cursor stays on the same visual row.
            local newEls = _buildPanelFocusables(win, self, win._activeTab) or {}
            local snap   = win._lastTabContentSnapshot
            local oldN   = snap and snap.n or -1
            local oldTab = snap and snap.tab or nil
            local newN   = #newEls
            local dirty  = (oldTab ~= win._activeTab) or (oldN ~= newN)
            if not dirty and newN > 0 and snap then
                dirty = (snap.firstId ~= newEls[1].id)
                     or (snap.lastId  ~= newEls[newN].id)
                     -- the stops move when the tab
                     -- scrolls (Skills' training rows stayed where the tab first
                     -- drew them, so the pad's sums and scroll-follow used old places)
                     or (snap.lastY ~= newEls[newN].y) or (snap.lastH ~= newEls[newN].h)
            end
            -- The Journal's Recipes page routes through CC.buildFocusables;
            -- its recipeRow zones shift screen-y on every scroll, and cone-nav
            -- must read fresh coords (else focus → wrong target). Rebuilding
            -- every frame cost ~6 ms a frame on a large test save (the list
            -- registers every recipe row: 1177 there). Rows only move when the list
            -- scrolls, its geometry changes, or the category dropdown opens,
            -- so the rebuild is keyed on those (scrollKey) instead.
            local scrollKey = nil
            -- Notebooks / Papers: rows move with the tab's one scroll and its view
            local jsub = win._journalSubTab or 1
            if win._activeTab == "journal" and (jsub == 2 or jsub == 3) and ZeD.JournalReaders then
                scrollKey = ZeD.JournalReaders.scrollKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- Loadouts: its scroll, the list chosen, the filter, the question, the lines
            if win._activeTab == "journal" and jsub == 5 and ZeD.JournalLists then
                scrollKey = ZeD.JournalLists.scrollKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- Journal: its last stop, Save, sits in the band and never moves, so the
            -- log's scroll, the Page list and the log's own layout (padKey: the picks, the
            -- tags, the groups) key the rebuild
            if win._activeTab == "journal" and jsub == 1 then
                scrollKey = tostring(win._journalScroll and win._journalScroll.scrollPos or 0) .. ":" .. tostring(win._journalPageOpen)
                    .. ":" .. (ZeD.JournalTab.padKey and ZeD.JournalTab.padKey(win) or "")
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            if win._activeTab == "journal" and jsub == 4 then
                local stk = win._jrecipeState
                if stk then
                    local sp = stk.scroll and stk.scroll.scrollPos or 0
                    local lg = stk._listGeo
                    scrollKey = tostring(sp) .. ":" .. tostring(lg and lg.y or 0) .. ":" .. tostring(lg and lg.h or 0)
                        .. ":" .. tostring(stk.catDropdownOpen) .. ":" .. tostring(stk.catDropdownScroll or 0)
                        -- (the band's stops are last and fixed: the card's scroll and its lists key it)
                        .. ":" .. tostring(stk.cardScroll and stk.cardScroll.scrollPos or 0)
                        .. ":" .. tostring(stk.altScroll and stk.altScroll.scrollPos or 0)
                        .. ":" .. tostring(stk.sortMenuOpen) .. ":" .. tostring(stk.showMenuOpen)
                    if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
                end
            end
            -- Equip: the doll's slots (and the list's rows) move with the tab's
            -- scroll, the drawer's size and the view
            if win._activeTab == "equip" then
                local sc = win._equipScroll
                local dp = win._drawerPanel
                scrollKey = tostring(sc and sc.scrollPos or 0) .. ":" .. tostring(ZeD.EquipDoll and ZeD.EquipDoll.view())
                    .. ":" .. tostring(dp and dp:getWidth()) .. ":" .. tostring(dp and dp:getHeight())
                    .. ":" .. tostring(win._equipSelected) .. ":" .. tostring(win._equipLayer)
                    .. ":" .. (ZeD.EquipLoadout and ZeD.EquipLoadout.scrollKey(win) or "")
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- Health and Thermal: the last stop is in the pinned
            -- band and never moves, so the body's scroll and the fold key the rebuild (the
            -- figure's parts and the injury rows move with the scroll)
            if win._activeTab == "health" then
                local sc = win._healthScroll
                scrollKey = tostring(sc and sc.scrollPos or 0) .. ":" .. tostring(win._healthFigureExpanded)
                    .. ":" .. tostring(win._healthMenuOpen) .. ":" .. tostring(win._healthView and win._healthView.h)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            if win._activeTab == "thermal" then
                local sc = win._thermalScroll
                scrollKey = tostring(sc and sc.scrollPos or 0) .. ":" .. tostring(win._thermalFigureExpanded)
                    .. ":" .. tostring(win._thermalMenuOpen) .. ":" .. tostring(win._thermalBodyRect and win._thermalBodyRect.h)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- Identity: its scroll and the Hair and beard rows (part, Out of reach open)
            if win._activeTab == "identity" and ZeD.IdentityTab.scrollKey then
                scrollKey = ZeD.IdentityTab.scrollKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- another mod's tab names what moves its stops (its scroll, its view)
            if ZeD_CharacterWindow.extScrollKey(win) then
                scrollKey = ZeD_CharacterWindow.extScrollKey(win)
                if not dirty and snap and snap.scrollKey ~= scrollKey then dirty = true end
            end
            -- a Find clear or Accept names where the hand lands (TabFind.land): taken at once
            if newEls._findLand then dirty = true end
            -- the Find text changes which rows are stops (a dimmed row is skipped)
            local findKey = ZeD.TabFind and ZeD.TabFind.text(win, win._activeTab) or ""
            if not dirty and snap and snap.findKey ~= findKey then dirty = true end
            local alwaysRebuild = false
            -- Identity-preserve focus by element id across rebuilds.
            -- Without this, scroll-driven array shifts (the Journal's Recipes
            -- list rebuilding as it scrolls) make focusedElementIdx point at a
            -- different element than the player expects.
            local preserveIdx = nil
            do
                local oldZ = nil
                for _, z in ipairs(win._focusRing) do
                    if z.zone == "charTabContent" then oldZ = z; break end
                end
                local oldEl = oldZ and oldZ.elements and oldZ.elements[oldZ.focusedElementIdx or 1]
                local oldId = oldEl and oldEl.id or nil
                if oldId then
                    for i, e in ipairs(newEls) do
                        if e.id == oldId then preserveIdx = i; break end
                    end
                end
            end
            if dirty or alwaysRebuild then
                win._lastTabContentSnapshot = {
                    tab     = win._activeTab,
                    scrollKey = scrollKey,
                    findKey = findKey,
                    n       = newN,
                    firstId = newEls[1] and newEls[1].id or nil,
                    lastId  = newEls[newN] and newEls[newN].id or nil,
                    lastY   = newEls[newN] and newEls[newN].y or nil,
                    lastH   = newEls[newN] and newEls[newN].h or nil,
                }
                -- a builder may name where focus lands (the Equip card opening / closing)
                Focus.setRingZoneElements(win, "charTabContent", newEls, newEls._focusIdx or preserveIdx)
                -- a Find landing takes the hand into the tab as well: the pad keyboard held the
                -- controller meanwhile, and the window's focus may be on another zone (the tab strip)
                if newEls._findLand then ZeD.TabFind.handIntoTab(win) end
                -- Stay focusable during equip card-mode transitions even
                -- if newEls is momentarily empty (first frame of card entry —
                -- back/action bounds stamped during render, AFTER this prerender
                -- ran). Next frame the ring rebuilds with real card elements.
                local inCardMode = (win._activeTab == "equip" and win._equipSelected)
                Focus.setZoneFocusable(win, "charTabContent", newN > 0 or inCardMode ~= nil)
            end
        end
    end

    -- What the controller reads between frames (FocusManager calls it before a press is worked on, a landing is
    -- looked for or the stops are listed): the tab's stops, when they waited for the mouse (Focus.stopsMayWait)
    win._focusFresh = function(w)
        local Focus = ZeD.Input and ZeD.Input.Focus
        if w._tabStopsStale and Focus and w._focusRing then
            w._tabStopsStale = nil
            content._tabStopsRefresh(content, Focus)
        end
    end

    -- The Character window's per-frame stop refresh (the container strip, the main list, the MC
    -- columns, the tab's stops, the item card). It lives outside the
    -- content's prerender, which does not run while the content is hidden (the tab drawer takes
    -- the whole window at 1280x720, UI scale 2.0): Health, Thermal, Identity, Skills and the
    -- Journal would have no stops. The drawer's prerender runs it then.
    content._focusRefresh = function(self)
        -- --------------------------------------------------------
        -- RING MODEL: PER-FRAME MAIN-INV REFRESH
        -- Runs AFTER the renderer finishes so _invRowItems is fresh.
        -- Always active (regardless of tab) because charMainInv is the
        -- persistent inventory-list zone in the ring. Rebuilds the focusable
        -- element array from the live item list, preserving focus by item
        -- identity. Uses dirty-check to avoid rebuilding unchanged lists.
        -- --------------------------------------------------------
        local Focus = ZeD.Input and ZeD.Input.Focus
        if Focus and win._focusRing then
            _refreshCharStripFocus(win, Focus)   -- (the container strip's stops)

            -- Guard: container source inventory still valid?
            if not self._inventory then
                Focus.setRingZoneElements(win, "charMainInv", {})
                Focus.setZoneFocusable   (win, "charMainInv", false)
                win._gpFocusedRowItem = nil
                win._invRowsForContainer = nil
                self._gpFocusedRowItem = nil
                win._lastInvRowSnapshot = nil
            else
                -- Guard: active container changed since rows were last seeded?
                if win._invRowsForContainer
                   and win._invRowsForContainer ~= win._activeContainer then
                    Focus.setRingZoneElements(win, "charMainInv", {})
                    Focus.setZoneFocusable   (win, "charMainInv", false)
                    win._gpFocusedRowItem = nil
                    win._invRowsForContainer = nil
                    self._gpFocusedRowItem = nil
                    win._lastInvRowSnapshot = nil
                else
                    -- Dirty check: only rebuild when item list actually changed.
                    -- Cannot compare table identity (renderer creates a new
                    -- flatItems table each frame), so compare count + edge items.
                    local oldSnap = win._lastInvRowSnapshot
                    local newItems = self._invRowItems
                    local oldN = oldSnap and #oldSnap or 0
                    local newN = newItems and #newItems or 0
                    local dirty = (oldN ~= newN)
                    if not dirty and newN > 0 and oldSnap then
                        dirty = (oldSnap[1] ~= newItems[1])
                             or (oldSnap[newN] ~= newItems[newN])
                    end
                    -- First frame (no snapshot yet) is always dirty.
                    if not oldSnap then dirty = true end
                    -- The rows' places change with the scroll, the
                    -- list or grid view and the column's width too; the targets
                    -- kept last build's places, so the pad picked by stale rows
                    local geo = tostring(self._scroll and self._scroll.scrollPos) .. ":" .. tostring(self._gridCell)
                        .. ":" .. tostring(self._renderW or self:getWidth()) .. ":" .. #(self._viewToggleRects or {}) .. ":" .. ZeD.InventoryRenderer.filterGen(self)
                        .. ":" .. tostring(self._rowView and self._rowView.bottom)   -- (the list's view: which rows are out of it)
                    if win._lastInvRowGeo ~= geo then win._lastInvRowGeo = geo; dirty = true end
                    -- (the container shown is part of what these rows are, by the object)
                    if win._lastInvRowInv ~= self._inventory then win._lastInvRowInv = self._inventory; dirty = true end

                    if dirty then
                        -- Snapshot: copy item refs into a separate table so the
                        -- next-frame comparison works (renderer's table changes).
                        local snap = {}
                        if newItems then
                            for si = 1, #newItems do snap[si] = newItems[si] end
                        end
                        win._lastInvRowSnapshot = snap

                        local newEls = _buildInvRowFocusables(win)
                        -- the toggle keeps the focus it has (it carries no item)
                        local keepId = nil
                        for _, z in ipairs(win._focusRing or {}) do
                            if z.zone == "charMainInv" then
                                local fe = z.elements and z.elements[z.focusedElementIdx or 1]
                                if fe and fe.isViewToggle then keepId = fe.id end
                            end
                        end
                        if #newEls == 0 then
                            Focus.setRingZoneElements(win, "charMainInv", {})
                            Focus.setZoneFocusable   (win, "charMainInv", false)
                            win._gpFocusedRowItem = nil
                            win._invRowsForContainer = nil
                            self._gpFocusedRowItem = nil
                        else
                            -- Preserve focus by item identity.
                            local preserveIdx = 1
                            local focItem = win._gpFocusedRowItem
                            if focItem then
                                for i, el in ipairs(newEls) do
                                    if el.item == focItem then
                                        preserveIdx = i
                                        break
                                    end
                                end
                                if preserveIdx == 1 and focItem ~= (newEls[1] and newEls[1].item) then
                                    local oldIdx = 1
                                    if win._focusRing then
                                        for _, z in ipairs(win._focusRing) do
                                            if z.zone == "charMainInv" then
                                                oldIdx = z.focusedElementIdx or 1
                                                break
                                            end
                                        end
                                    end
                                    -- (the neighbouring ROW: the view button
                                    -- and the Filter come after the rows, never a stand-in for one)
                                    local nRows = 0
                                    for _, ne in ipairs(newEls) do if ne.item then nRows = nRows + 1 end end
                                    preserveIdx = math.min(oldIdx, math.max(1, nRows))
                                end
                            end
                            if keepId then
                                for i, el in ipairs(newEls) do if el.id == keepId then preserveIdx = i end end
                            end

                            Focus.setRingZoneElements(win, "charMainInv", newEls, preserveIdx)
                            Focus.setZoneFocusable   (win, "charMainInv", true)
                            -- Update tracked item to match new resolved index.
                            local resolvedEl = newEls[preserveIdx]
                            if resolvedEl then
                                win._gpFocusedRowItem = resolvedEl.item
                                self._gpFocusedRowItem = resolvedEl.item
                            end
                        end
                    end
                end
            end
        end

        -- Per-frame refresh for per-column charMC<n> zones.
        -- Each MC selection has its own ring zone; loop and refresh elements.
        -- Identity-preserve via _gpFocusedMCItem (per-zone preserveIdx). Ring
        -- structure (zone count) updated by _rebuildCharMCRingZones on MC
        -- toggle, not here. Only changed columns rebuild (_refreshCharMCZones).
        if Focus and win._focusRing then
            _refreshCharMCZones(win, Focus)
        end

        -- An open pop-up list lives while its tab's
        -- card shows; the drawer folding, an item card opening over it or the tab
        -- going away shuts it (as leaving the tab does), never a hitch in drawing
        do
            local shown = win._drawerOpen and win._drawerMode == "tab" and win._drawerItem == nil
            _shutTabLists(win, shown and win._activeTab or nil)
        end

        -- the tab's stops (content._tabStopsRefresh, above). With the mouse
        -- and keyboard in use, no controller mark showing and no landing waiting (Focus.stopsMayWait) they wait; the
        -- first frame after, and anything the controller does first (FocusManager's win._focusFresh), rebuilds them
        -- from scratch.
        if Focus and win._focusRing then
            if not (Focus.stopsMayWait and Focus.stopsMayWait(win)) then
                win._tabStopsStale = nil
                content._tabStopsRefresh(self, Focus)
            else
                win._tabStopsStale, win._lastTabContentSnapshot = true, nil
            end
        end

        -- Per-frame refresh for the charItemCard zone. The card's toggleRects
        -- and verbRects are stamped by the card render each frame; this block
        -- picks them up into the ring zone. Focusable state tracks card
        -- visibility (`_drawerItem ~= nil`), NOT `_drawerMode` — on non-Loot
        -- tabs the card overlays the tab drawer while `_drawerMode` stays
        -- "tab", and the card must remain interactive in that overlay state.
        -- Mirrors World's worldItemCard refresh. Zone still auto-dismisses
        -- on tab-switch because _switchTabForNav clears _drawerItem.
        if Focus and win._focusRing then
            local cardVisible = (win._drawerItem ~= nil)
            local cardEls = cardVisible and _buildCardActionFocusables(win) or {}
            Focus.setRingZoneElementsKeepId(win, "charItemCard", cardEls)
            Focus.setZoneFocusable   (win, "charItemCard", cardVisible and #cardEls > 0)
        end
    end

    -- The title, every frame, from the window itself: every way the tab changes (a click on
    -- the strip, LB / RB, the D-pad, a script) shows in it
    local _baseWinPrerender = win.prerender
    win.prerender = function(self)
        -- (Loot with the drawer left in tab mode folds every frame the window shows, not only when the drawer draws:
        -- a drawer still sliding could miss it; QA's b11n run, Nov 11 2026)
        lootDrawerFallback(self)
        composeCharTitle(self)
        composeCharHealth(self)
        _baseWinPrerender(self)
    end

    -- Draw drag ghost at window level so it renders on top of all panels
    local _baseWinRender = win.render
    win.render = function(self)
        _baseWinRender(self)
        if content._drag and content._drag:isActive() then
            content._drag:drawGhost(self)
        end
        -- an Equip row's drag (EquipmentTab: the drawer owns that mouse)
        if win._equipDrag and win._equipDrag:isActive() then
            win._equipDrag:drawGhost(self)
        end
        -- The structure line between the drawer and the inventory (after all
        -- children, so the drawer's content never covers it). It runs from the
        -- title bar's line to the help line's line only: never across the title
        -- bar, the help line or the frame. None while windowshaded.
        if win._dividerX and not self.windowShaded then
            local T = ZeD.T
            local brd = T.borderS
            local y0 = self:titleBarHeight()
            local y1 = self:getHeight() - self:footerHeight()
            if y1 > y0 then self:drawRect(win._dividerX, y0, T.px(1), y1 - y0, brd.a or 1, brd.r, brd.g, brd.b) end
        end
        saveCharStateThrottled(self)  -- keep the remembered layout current (about once a second)
    end

    -- The help line's words when the pointer rests on nothing with help of its
    -- own: what the inventory side shows ("9 items | 6.3/20kg"; ZeD.Help.take)
    win.getStatusLine = function(self) return self._statusLine end

    -- Curtain (WindowCurtain.lua): the inventory side (right of the drawer)
    -- rolls up under its title while a tab drawer stays open
    ZeD.Curtain.attach(win, {
        side = "right",
        sideW = function() return content:getWidth() + ZeD.T.px(CONTAINER_STRIP_W) end,
        canRoll = function()
            return win._drawerOpen and win._drawerMode == "tab" and win._activeTab ~= nil
                and #(win._mcSelected or {}) == 0 and (win._rolled or content:isVisible())
        end,
        chip = function()
            local inv = content._inventory
            local e = win._containers and win._containers[win._activeContainer]
            local name = (e and not e.isMain and e.name) or getText("IGUI_InventoryTooltip")
            return name, inv and inv:getItems():size() or 0
        end,
        dropInv = function() return content._inventory end,
        onChange = function(rolled)
            if not rolled and _syncRingZonesToActiveTab then _syncRingZonesToActiveTab(win, content) end
        end,
        onFrame = function()
            local Focus = ZeD.Input and ZeD.Input.Focus
            if not (Focus and win._focusRing) then return end
            Focus.setRingZoneElements(win, "charMainInv", {})
            Focus.setZoneFocusable(win, "charMainInv", false)
            local el = ZeD.Curtain.padElement(win, containerStrip:getX(), containerStrip:getY())
            Focus.setRingZoneElements(win, "charContainerStrip", el and { el } or {}, 1)
            Focus.setZoneFocusable(win, "charContainerStrip", el ~= nil)
        end,
    })
    -- Halves (WindowHalves.lua): the drawer (left) and the inventory (right) each roll up
    -- and pin on their own; the pins sit at the title bar's two ends
    ZeD.Halves.attach(win, { key = "char", side = "left", strip = "_tabStripPanel", zone = "charTitlePins" })

    -- ----------------------------------------------------------------
    -- MOUSE HANDLERS — the list's clicks, selection, drags, scroll and right-click
    -- ----------------------------------------------------------------
    local countSelected        = r.countSelected
    local findIndex            = r.findIndex
    local handleDrop           = r.handleDrop

    -- Select all: every row of the list (the column under the pointer), the card shut; a double-click on the list's
    -- empty space (ZeD_BoxSelect.doubleEmpty; punch list 146)
    content.zedSelectAll = function(self)
        local _, cs = getColumnAtX(self, self:getMouseX())
        local sel = (cs and cs.selectedItems) or self._selectedItems
        local flat = (cs and cs.flatItems) or self._flatItems
        if not (sel and flat) then return false end
        for k in pairs(sel) do sel[k] = nil end
        for _, it in ipairs(flat) do sel[it] = true end
        local last = flat[#flat]
        if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
        self._padMarks = true
        updateDrawer(self)
        return true
    end

    content.onMouseDown = function(self, x, y)
        self._padMarks = nil   -- (a mouse press: the mouse's card rule again)
        -- the container buttons' row
        do
            local ccZone = self:hitZoneAt(x, y)
            local ccId = ccZone and ccZone.id
            if type(ccId) == "string" and ccId:sub(1, 3) == "cc:" and ZeD.ContainerControls then
                ZeD.ContainerControls.press(self, tonumber(ccId:sub(4)))
                return true
            end
        end

        -- Multi-container: column-aware scroll check. Only a press on a bar as drawn is the bar's (hitY): the strip
        -- above it, beside the heading's controls, holds the Filter's Clear and the end of its chips' lines.
        if #(win._mcSelected or {}) > 0 and self._colStates then
            for _, cs in ipairs(self._colStates) do
                local sy = cs.scroll and cs.scroll:hitY(x, y)
                if sy then
                    cs.scroll:handleMouseDown(sy)
                    self._activeScroll = cs.scroll
                    return true
                end
            end
        else
            local sy = self._scroll:hitY(x, y)
            if sy then
                self._scroll:handleMouseDown(sy)
                return true
            end
        end

        local zone = self:hitZoneAt(x, y)
        if not zone then
            -- empty space: a double-click selects every row; a drag from here draws a box that selects the rows it
            -- crosses (punch list 146)
            if ZeD.BoxSelect and ZeD.BoxSelect.doubleEmpty and ZeD.BoxSelect.doubleEmpty(self, x, y) and self.zedSelectAll then
                self:zedSelectAll()
                return true
            end
            if ZeD.BoxSelect then
                local _, bCs = getColumnAtX(self, x)
                local bSel = (bCs and bCs.selectedItems) or self._selectedItems
                if bSel then
                    ZeD.BoxSelect.start(self, x, y, bSel, bCs and function(px) return (getColumnAtX(self, px)) end or nil)
                end
            end
            return true
        end
        local zid = zone.id

        -- XFER button click (multi-container transfer)
        if type(zid) == "string" and zid:sub(1, 5) == "xfer:" then
            local targetColIdx = tonumber(zid:sub(6))
            local colStates = self._colStates or {}
            local srcCol = self._activeCol or #colStates
            local srcCs = colStates[srcCol]
            local dstCs = colStates[targetColIdx]
            if srcCs and dstCs and srcCs ~= dstCs then
                local items = {}
                for item, _ in pairs(srcCs.selectedItems) do
                    items[#items + 1] = item
                end
                if #items > 0 then
                    handleDrop(self, items, srcCs.inventory)
                    srcCs.selectedItems = {}
                    srcCs.lastClickedItem = nil
                end
            end
            return true
        end

        -- Column divider drag → start resize
        if type(zid) == "string" and zid:sub(1, 4) == "div:" then
            local col = zid:sub(5)
            local colW = self._colWidths
            if colW and colW[col] then
                self._colDrag = {
                    col    = col,
                    startX = getMouseX(),
                    startW = colW[col],
                }
                self:setCapture(true)
            end
            return true
        end

        if type(zid) == "string" and zid:sub(1, 4) == "hdr:" then
            local col = zid:sub(5)
            -- Column-aware: sort the clicked column
            local hdrColIdx, hdrCs = getColumnAtX(self, x)
            if hdrCs then
                if hdrCs.sortCol == col then
                    hdrCs.sortAsc = not hdrCs.sortAsc
                else
                    hdrCs.sortCol = col
                    hdrCs.sortAsc = true
                end
                hdrCs.scroll:setScrollPos(0)
            else
                if self._sortCol == col then
                    self._sortAsc = not self._sortAsc
                else
                    self._sortCol = col
                    self._sortAsc = true
                end
                self._scroll:setScrollPos(0)
            end
            return true
        end

        -- a column's view button (InventoryRenderer: "view:flip:<container>")

        if type(zid) == "string" and zid:sub(1, 5) == "view:" then

            ZeD.InventoryRenderer.onViewZone(zid, self)

            return true

        end


        if type(zid) == "string" and zid:sub(1, 4) == "cat:" then
            local cat = zid:sub(5)
            -- Column-aware: collapse in the clicked column
            local catColIdx, catCs = getColumnAtX(self, x)
            local collapsed = (catCs and catCs.collapsedGroups) or self._collapsedGroups
            if collapsed[cat] then
                collapsed[cat] = nil
            else
                collapsed[cat] = true
            end
            return true
        end

        -- Stack chevron toggle — flips the expanded state for this
        -- fullType in the clicked column. Next render pass emits children
        -- (expanded) or hides them (collapsed). Key is the stack's fullType.
        if type(zid) == "string" and zid:sub(1, 6) == "stack:" then
            local key = zid:sub(7)
            local stkColIdx, stkCs = getColumnAtX(self, x)
            local exp = (stkCs and stkCs.expandedStacks) or self._expandedStacks
            if exp then
                exp[key] = not exp[key]
            end
            return true
        end

        local item = zid
        if type(item) == "string" then return true end  -- not an item
        -- double-click: vanilla's quick use (InventoryRenderer.doubleClick)
        if not isCtrlKeyDown() and not isShiftKeyDown() and self._playerObj
            and ZeD.InventoryRenderer.doubleClick(self, item, self._playerObj:getPlayerNum()) then
            self._deferredSelect = nil
            return true
        end

        local screenX, screenY = getMouseX(), getMouseY()
        self._deferredSelect = nil

        -- Determine which column this item is in
        local colIdx, colCs = getColumnAtX(self, x)
        local sel, lastClicked, flatItems
        if colCs then
            sel = colCs.selectedItems
            lastClicked = colCs.lastClickedItem
            flatItems = colCs.flatItems
            self._dragSourceCol = colIdx
            self._dragSourceInv = colCs.inventory
            self._activeCol = colIdx
        else
            sel = self._selectedItems
            lastClicked = self._lastClickedItem
            flatItems = self._flatItems
            self._dragSourceCol = nil
            self._dragSourceInv = self._inventory
        end

        if isCtrlKeyDown() then
            self._padMarks = true   -- (picking rows: the card stays shut, even at one; punch list 146)
            if sel[item] then
                sel[item] = nil
            else
                sel[item] = true
            end
            if colCs then colCs.lastClickedItem = item
            else self._lastClickedItem = item end
            local dragItems = {}
            for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
            if #dragItems > 0 then
                -- (the chip counts what the rows carry: a closed stack's row is its whole stack)
                self._drag:beginPending(dragItems, dragItems[1], screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            end

        elseif isShiftKeyDown() and lastClicked then
            self._padMarks = true   -- (picking rows: the card stays shut, even at one; punch list 146)
            local fromIdx = findIndex(flatItems, lastClicked)
            local toIdx   = findIndex(flatItems, item)
            if fromIdx and toIdx then
                local lo = math.min(fromIdx, toIdx)
                local hi = math.max(fromIdx, toIdx)
                for i = lo, hi do
                    sel[flatItems[i]] = true
                end
            end
            local dragItems = {}
            for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
            if #dragItems > 0 then
                self._drag:beginPending(dragItems, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            end

        else
            if sel[item] then
                self._deferredSelect = { item = item, colIdx = colIdx }
                local dragItems = {}
                for it, _ in pairs(sel) do dragItems[#dragItems + 1] = it end
                self._drag:beginPending(dragItems, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, dragItems, self._dragSourceInv))
            else
                -- Clear old table, set new selection
                for k in pairs(sel) do sel[k] = nil end
                sel[item] = true
                if colCs then colCs.lastClickedItem = item
                else self._lastClickedItem = item end
                self._drag:beginPending({item}, item, screenX, screenY,
                    ZeD.InventoryRenderer.dragItems(self, {item}, self._dragSourceInv))
            end
        end

        -- Sync column selection back to self for updateDrawer compatibility
        if colCs then
            self._selectedItems = sel
            self._lastClickedItem = colCs.lastClickedItem
        end

        -- Ctrl/shift resolve immediately — update drawer
        if not self._deferredSelect then
            updateDrawer(self)
        end

        return true
    end

    content.onMouseUp = function(self, x, y)
        -- Release active scroll (multi-container column scroll)
        if self._activeScroll then
            self._activeScroll:handleMouseUp()
            self._activeScroll = nil
        end
        self._scroll:handleMouseUp()

        if self._box then
            local last, bCol = ZeD.BoxSelect.finish(self)
            if last then
                self._padMarks = true   -- (rows picked by a box: the card stays shut, even at one)
                local cs = bCol and self._colStates and self._colStates[bCol]
                if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
            end
            updateDrawer(self)
            return true
        end

        -- Column divider drag → finalize
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end

        if self._drag:isActive() then
            local items = self._drag:complete()
            handleDrop(self, items, self._dragSourceInv)
            self:setCapture(false)
            self._deferredSelect = nil
            self._dragSourceCol = nil
            self._dragSourceInv = nil
            updateDrawer(self)
            return true
        end

        if self._drag:isPending() then
            self._drag:cancel()
        end

        if self._deferredSelect then
            local def = self._deferredSelect
            self._deferredSelect = nil
            local item = def.item or def
            local colIdx = type(def) == "table" and def.colIdx or nil
            local sel = self._selectedItems

            -- Use the column's selection if available
            if colIdx and self._colStates and self._colStates[colIdx] then
                sel = self._colStates[colIdx].selectedItems
            end

            if sel[item] and countSelected(sel) == 1 then
                for k in pairs(sel) do sel[k] = nil end
                if colIdx and self._colStates and self._colStates[colIdx] then
                    self._colStates[colIdx].lastClickedItem = nil
                else
                    self._lastClickedItem = nil
                end
            else
                for k in pairs(sel) do sel[k] = nil end
                sel[item] = true
                if colIdx and self._colStates and self._colStates[colIdx] then
                    self._colStates[colIdx].lastClickedItem = item
                else
                    self._lastClickedItem = item
                end
            end
            -- Sync back for updateDrawer
            self._selectedItems = sel
        end

        self._dragSourceCol = nil
        self._dragSourceInv = nil
        updateDrawer(self)
        return true
    end

    content.onMouseMove = function(self, dx, dy)
        if self._box then ZeD.BoxSelect.move(self, self:getMouseX(), self:getMouseY()); return true end
        local T = ZeD.T
        local my = self:getMouseY()
        self._scroll:handleMouseMove(my - self._scroll.y)   -- (on the bar's own y, as its press is)

        -- Column divider drag → update width (columns are right-aligned, so negate delta)
        if self._colDrag then
            local cd = self._colDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            self._colWidths[cd.col] = newW
            return true
        end

        if self._drag:isPending() then
            if self._drag:checkThreshold(getMouseX(), getMouseY()) then
                self:setCapture(true)
                self._deferredSelect = nil
                win._drawerItem = nil  -- hide item card on drag
            end
        elseif self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end

        return true
    end

    content.onMouseMoveOutside = function(self, dx, dy)
        if self._box then ZeD.BoxSelect.move(self, self:getMouseX(), self:getMouseY()); return true end
        local T = ZeD.T
        -- Column divider drag continues outside (negate delta for right-aligned columns)
        if self._colDrag then
            local cd = self._colDrag
            local delta = getMouseX() - cd.startX
            local newW = math.max(T.px(30), math.min(math.floor(self:getWidth() / 2), cd.startW - delta))
            self._colWidths[cd.col] = newW
            return true
        end
        if self._drag:isActive() then
            self._drag:updateGhostPos(getMouseX(), getMouseY())
        end
        return true
    end

    content.onMouseUpOutside = function(self, x, y)
        if self._box then
            local last, bCol = ZeD.BoxSelect.finish(self)
            if last then
                self._padMarks = true   -- (rows picked by a box: the card stays shut, even at one)
                local cs = bCol and self._colStates and self._colStates[bCol]
                if cs then cs.lastClickedItem = last else self._lastClickedItem = last end
            end
            updateDrawer(self)
            return true
        end
        -- Column divider drag → finalize
        if self._colDrag then
            self._colDrag = nil
            self:setCapture(false)
            return true
        end
        if self._drag:isActive() then
            local items = self._drag:complete()
            handleDrop(self, items, self._dragSourceInv)
            self:setCapture(false)
            self._deferredSelect = nil
            self._dragSourceCol = nil
            self._dragSourceInv = nil
            return true
        end
        if self._drag:isPending() then
            self._drag:cancel()
        end
        self._deferredSelect = nil
        self._dragSourceCol = nil
        self._dragSourceInv = nil
        return true
    end

    content.onRightMouseDown = function(self, x, y)
        self._padMarks = nil
        if self._drag:isActive() or self._drag:isPending() then
            self._drag:cancel()
            self:setCapture(false)
            self._deferredSelect = nil
            return true
        end
        return true
    end

    content.onRightMouseUp = function(self, x, y)
        if self._drag:isActive() or self._drag:isPending() then return true end

        local colIdx, colCs = getColumnAtX(self, x)
        local inv = (colCs and colCs.inventory) or self._inventory

        -- The menu acts on the row under the cursor, as in vanilla: a row that
        -- is not already selected becomes the selection first (see _rmbMenuItems).
        local menuItems, reselected = _rmbMenuItems(self, x, y, colIdx, colCs)
        if reselected then updateDrawer(self) end

        if #menuItems == 0 then return true end

        local playerNum = self._playerObj:getPlayerNum()
        local isInInv = inv:isInCharacterInventory(self._playerObj)
        ISInventoryPaneContextMenu.createMenu(
            playerNum, isInInv, menuItems,
            self:getAbsoluteX() + x, self:getAbsoluteY() + y
        )
        return true
    end

    content.onRightMouseDownOutside = function(self, x, y)
        if self._drag:isActive() or self._drag:isPending() then
            self._drag:cancel()
            self:setCapture(false)
            self._deferredSelect = nil
            return true
        end
        return true
    end

    content.onMouseWheel = function(self, del)
        -- over the container buttons' ribbon: it scrolls sideways
        if ZeD.ContainerControls and ZeD.ContainerControls.wheel(self, del) then return true end
        -- Multi-container: scroll the column under the mouse
        if #(win._mcSelected or {}) > 0 and self._colStates then
            local mx = self:getMouseX()
            for _, cs in ipairs(self._colStates) do
                if mx >= cs.renderX and mx < cs.renderX + cs.renderW then
                    cs.scroll:handleMouseWheel(del)
                    return true
                end
            end
        end
        self._scroll:handleMouseWheel(del)
        return true
    end
end

-- ============================================================================
-- KEY BINDING
-- ============================================================================

-- Save + remove vanilla handler so only ZeD responds to "Toggle Inventory"
local _vanillaInvKeyPressed = ISInventoryPage.onKeyPressed
Events.OnKeyPressed.Remove(_vanillaInvKeyPressed)

-- A window that fails to open trips safe mode (SafeMode.lua): both windows close
-- and the game's own pages show. The press still gets an inventory: the one the
-- trip just showed, or, if that did not happen, vanilla's key handler opens it.
local function _openOrStepAside(open, playerNum, where)
    local ok, err = pcall(open, playerNum)
    if ok then return true end
    ZeD.Safe.trip(where, err)
    local vi = getPlayerInventory(playerNum or 0)
    if vi and not vi:getIsVisible() and (playerNum or 0) == 0 then
        pcall(_vanillaInvKeyPressed, getCore():getKey("Toggle Inventory"))
    end
    return false
end

--- Open or close the two windows as a pair: the inventory key's action, and
--- the same sequence for the gamepad's Y tap (FocusManager). Behavior:
---   Both closed     → open both
---   Both open       → close both
---   One open        → open the missing one
--- While the game is paused, the Character window alone (see below).
function ZeD_CharacterWindow.toggleBothPaired(playerNum)
    playerNum = playerNum or 0
    if not ZeD.windowsFor(playerNum) then return end   -- (split-screen: the game's own, ZeD.windowsFor)
    if not getSpecificPlayer(playerNum) then return end
    -- (never for a dead character: the windows reopen for the next one)
    if getSpecificPlayer(playerNum):isDead() then return end
    if not getPlayerInventory(playerNum) then return end
    if tostring(getCore():getGameMode()) == "Tutorial" then return end
    -- safe mode: the game's own inventory answers (its key handler, its Y prompt)
    if ZeD.Safe.on("windows") then return end
    -- paused: the Character window alone, to look at, rather than the game's own pages; its
    -- actions wait for the game to play again (ZeD_PausedLook.lua)
    if getGameSpeed() <= 0 then
        if ZeD_CharacterWindow.isOpen(playerNum) then ZeD_CharacterWindow.toggle(playerNum)
        else _openOrStepAside(ZeD_CharacterWindow.toggle, playerNum, "the Character window failed to open") end
        return
    end

    local charOpen  = ZeD_CharacterWindow.isOpen(playerNum)
    local worldOpen = ZeD_WorldWindow.isOpen(playerNum)

    if not charOpen and not worldOpen then
        if not _openOrStepAside(ZeD_CharacterWindow.toggle, playerNum, "the Character window failed to open") then return end
        if not _openOrStepAside(ZeD_WorldWindow.open, playerNum, "the World window failed to open") then return end
    elseif charOpen and worldOpen then
        ZeD_CharacterWindow.toggle(playerNum)
        ZeD_WorldWindow.close(playerNum)
    elseif charOpen and not worldOpen then
        if not _openOrStepAside(ZeD_WorldWindow.open, playerNum, "the World window failed to open") then return end
    elseif not charOpen and worldOpen then
        if not _openOrStepAside(ZeD_CharacterWindow.toggle, playerNum, "the Character window failed to open") then return end
    end

    _hideVanilla()
end

--- Window-pair invariant for gamepad mode. Opens whichever of the pair
--- is currently closed. Idempotent — no-op if both are already open. Called
--- by FocusManager (LB/RB, the Y tap, the switch from mouse and keys to a pad)
--- and wherever else a pad opens the pair (the wheels, chat, routes). Mouse
--- mode keeps its asymmetric open/closed behavior; this helper is
--- gamepad-only and is gated by callers, not internally.
function ZeD_CharacterWindow.ensureBothOpenForGamepad(playerNum)
    playerNum = playerNum or 0
    if ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.held and ZeD.Input.Focus.held() then return end   -- (the join screen)
    if not ZeD.windowsFor(playerNum) then return end   -- (split-screen: the game's own, ZeD.windowsFor)
    if not getSpecificPlayer(playerNum) then return end
    if getSpecificPlayer(playerNum):isDead() then return end
    if getGameSpeed() <= 0 then return end
    if not getPlayerInventory(playerNum) then return end
    if tostring(getCore():getGameMode()) == "Tutorial" then return end
    if ZeD.Safe.on("windows") then return end   -- safe mode: no ZeD windows (SafeMode.lua)

    if not ZeD_CharacterWindow.isOpen(playerNum) then
        if not _openOrStepAside(ZeD_CharacterWindow.toggle, playerNum, "the Character window failed to open") then return end
    end
    if ZeD_WorldWindow and not ZeD_WorldWindow.isOpen(playerNum) then
        if ZeD_WorldWindow.open and not _openOrStepAside(ZeD_WorldWindow.open, playerNum, "the World window failed to open") then return end
    end
    _hideVanilla()
end

-- On death both windows close (vanilla destroys its inventory pages too). They
-- are built afresh on the next open, so after a respawn they belong to the new
-- character, not the dead one (left open, they kept the dead player, queued
-- actions against it and never rebound).
Events.OnPlayerDeath.Add(function(playerObj)
    pcall(function()
        local pn = playerObj:getPlayerNum()
        local cw = _charWins[pn]
        if cw and cw._playerObj == playerObj then ZeD_CharacterWindow.toggle(pn) end
        local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
        if ww and ww._playerObj == playerObj and ZeD_WorldWindow.close then ZeD_WorldWindow.close(pn) end
    end)
end)

-- A respawned character is a new player object with empty modData, so it would
-- open both windows at their default place and size. The dead character's
-- remembered layout (ZeD_WinState: position, size, tab, accent of each window)
-- is kept in memory and handed to the new character when it has none of its
-- own. Registered once; everything lives on one ZeD field, so no new local
-- names are added to this big file's main chunk. The stash
-- is taken after the listener above has closed the windows, so it holds their
-- final layout, and is dropped on leaving to the main menu so it never reaches
-- a character in another save. One stash a local player (stash[pn]): in split
-- view each player's respawn gets back their own layout, never another's.
if not ZeD._winStateCarry then
    ZeD._winStateCarry = { stash = {} }
    function ZeD._winStateCarry.copy(src)
        if type(src) ~= "table" then return src end
        local out = {}
        for k, v in pairs(src) do out[k] = ZeD._winStateCarry.copy(v) end
        return out
    end
    Events.OnPlayerDeath.Add(function(playerObj)
        pcall(function()
            local pn = playerObj:getPlayerNum()
            local md = playerObj:getModData()
            ZeD._winStateCarry.stash[pn] = md.ZeD_WinState and ZeD._winStateCarry.copy(md.ZeD_WinState) or nil
        end)
    end)
    Events.OnCreatePlayer.Add(function(playerNum)
        if type(playerNum) ~= "number" then return end
        pcall(function()
            local stash = ZeD._winStateCarry.stash[playerNum]
            if not stash then return end
            local p = getSpecificPlayer(playerNum)
            if not p then return end
            local md = p:getModData()
            if md.ZeD_WinState == nil then
                md.ZeD_WinState = ZeD._winStateCarry.copy(stash)
            end
            ZeD._winStateCarry.stash[playerNum] = nil
        end)
    end)
    if Events.OnMainMenuEnter then
        Events.OnMainMenuEnter.Add(function() ZeD._winStateCarry.stash = {} end)
    end
end

--- The inventory key's handler (kept on the module so a test script can press
--- it). In safe mode the game's own handler answers it.
function ZeD_CharacterWindow._onKeyPressed(key)
    if ZeD.Safe.on("windows") then
        _vanillaInvKeyPressed(key)
        return
    end
    if getCore():isKey("Toggle Inventory", key) then
        ZeD_CharacterWindow.toggleBothPaired(0)
        return
    end
    -- Pass non-inventory keys through to vanilla handler
    _vanillaInvKeyPressed(key)
end
Events.OnKeyPressed.Add(ZeD_CharacterWindow._onKeyPressed)

-- A mod loaded after this file may hang its own wrap of the game's handler on the event, and the
-- inventory key would flip the game's pages behind ZeD's windows. Every mod has loaded by now: that
-- wrap comes off the same way and takes the pass-through above, so the mod's other keys still arrive.
Events.OnGameStart.Add(function()
    local cur = ISInventoryPage.onKeyPressed
    if cur and cur ~= _vanillaInvKeyPressed then
        Events.OnKeyPressed.Remove(cur)
        _vanillaInvKeyPressed = cur
    end
end)

-- Safe mode's hand-back (SafeMode.lua): both windows close, even one that broke
-- halfway through opening, and the game's own inventory and loot pages show.
-- Taking over again hides those pages, as a world's first frame does;
-- the windows stay closed until the inventory key opens them.
local function _closeForSafeMode()
    -- (every local player's pair: with split view on, ZeD.windowsFor, players 2-4 may have theirs open too.
    -- The first player's World window is always force-closed, as before; another player's only when open, so
    -- nothing of theirs, such as the floor container, is cleared for a window they never had)
    for pn = 0, 3 do
        if _charWins[pn] then
            local ok = pcall(ZeD_CharacterWindow.toggle, pn)
            if not ok or _charWins[pn] then
                local w = _charWins[pn]
                _charWins[pn] = nil
                pcall(function()
                    if ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.unregisterWindow(w) end
                end)
                pcall(w.removeFromUIManager, w)
            end
        end
        if ZeD_WorldWindow and ZeD_WorldWindow.forceClose
           and (pn == 0 or (ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn))) then
            pcall(ZeD_WorldWindow.forceClose, pn)
        end
    end
    -- (every player whose pages ZeD hid gets them back)
    for p = 0, 3 do
        if ZeD.windowsFor(p) then
            local vi, vl = getPlayerInventory(p), getPlayerLoot(p)
            if vi then vi:setVisible(true) end
            if vl then vl:setVisible(true) end
        end
    end
end
ZeD.Safe.register("windows", { leave = _closeForSafeMode, enter = function() _hideVanilla() end })

-- A resolution change keeps every open window on the new screen
if Events.OnResolutionChange then
    Events.OnResolutionChange.Add(function() for _, w in pairs(_charWins) do fitCharToScreen(w) end end)
-- split view: a player joining or leaving resizes every player's part of the screen (player 1's halves when player 2
-- joins), so each window refits to its own part then too (off until ZeD.splitWindows)
local function _refitChars()
    if not ZeD.splitWindows then return end
    for pn = 1, 3 do
        -- (a player whose part became too small for ZeD's windows, a third player joining on a 1080p screen: their ZeD
        -- windows close and the game's own take over, the director's choice A)
        if getSpecificPlayer(pn) and not ZeD.windowsFor(pn) then
            local w = _charWins[pn]
            if w then
                local ok = pcall(ZeD_CharacterWindow.toggle, pn)
                if not ok or _charWins[pn] then
                    _charWins[pn] = nil
                    pcall(function() if ZeD.Input and ZeD.Input.Focus then ZeD.Input.Focus.unregisterWindow(w) end end)
                    pcall(w.removeFromUIManager, w)
                end
            end
            if ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn) then
                pcall(ZeD_WorldWindow.forceClose, pn)
            end
        end
    end
    for _, w in pairs(_charWins) do fitCharToScreen(w) end
end
Events.OnCreatePlayer.Add(_refitChars)
Events.OnPlayerDeath.Add(_refitChars)
end

-- Save state on game save (each window into its own character's modData)
Events.OnPostSave.Add(function()
    for _, w in pairs(_charWins) do saveCharState(w) end
    -- Persist global theme + per-window accents to player modData
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Theme = md.ZeD_Theme or {}
        md.ZeD_Theme.base   = ZeD.currentBase
        md.ZeD_Theme.accent = ZeD.currentAccent
        md.ZeD_Theme.size   = ZeD.currentSize
        if _charWins[0] and _charWins[0]._accentKey then
            md.ZeD_Theme.charAccent = _charWins[0]._accentKey
        end
        -- (the first player's on purpose: the theme and the window accents are saved with player 1)
        local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(0)
        if worldWin and worldWin._accentKey then
            md.ZeD_Theme.worldAccent = worldWin._accentKey
        end
    end
end)

-- ============================================================================
-- HIDE THE VANILLA PAGES FROM A WORLD'S FIRST FRAME
-- Not only after the first ZeD open: otherwise a fresh load shows the vanilla
-- collapsed strips at the top of the screen until the player presses the
-- inventory key. The pages are created on OnCreatePlayer, so a
-- short OnTick retry covers any ordering difference between builds.
-- A respawn rebuilds those pages (vanilla's OnCreatePlayer) without a new
-- OnGameStart, and both ZeD windows closed on the death, so the retry is armed
-- again whenever player one is created. Listener order is not fixed, so it
-- keeps hiding for a short while after it first finds a page (the old page
-- may still be the one it finds first), then stops.
-- ============================================================================
local _hideTries, _hideSeen = 0, 0
local function _hideVanillaTick()
    _hideTries = _hideTries + 1
    if getPlayerInventory(0) then
        _hideVanilla()
        _hideSeen = _hideSeen + 1
    end
    if _hideSeen >= 30 or _hideTries >= 120 then
        Events.OnTick.Remove(_hideVanillaTick)
    end
end
local function _armHideVanilla()
    _hideTries, _hideSeen = 0, 0
    Events.OnTick.Remove(_hideVanillaTick)
    Events.OnTick.Add(_hideVanillaTick)
end
Events.OnGameStart.Add(_armHideVanilla)
Events.OnCreatePlayer.Add(function(playerNum)
    -- (player 1, or with split view on any player whose windows are ZeD's)
    if playerNum == 0 or ZeD.windowsFor(playerNum) then _armHideVanilla() end
end)

-- ----------------------------------------------------------------------------
--- Toggle a container's column in the Loot tab's multi-column view, by its
--- ItemContainer, as a click on its icon in the container strip does (test
--- scripts drive it from here, e.g. for the Workshop gallery's shot of several
--- bags open side by side). Returns true when the container was found. Loot
--- tab only, like the click. pn: whose window (nil: the first player's).
-- ----------------------------------------------------------------------------
function ZeD_CharacterWindow.toggleColumn(inv, pn)
    local win = _charWins[pn or 0]
    if not (win and inv and win._mainContent) then return false end
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            mcToggleContainer(win, win._mainContent, i)
            return true
        end
    end
    return false
end
