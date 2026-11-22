-- ZeDUI/tools/qa/pad_reach_fixes_sim.lua
-- (Nov 16 2026, QA's controller and mouse reach audit, punch list 264-268) Runs the real code of each fix, pulled out of
-- its file, with stubs for the game:
--   264  the Journal delete question gives the pad back to the entry (Cancel) or its neighbor (Delete); the Equip tab
--        lands on the next filled slot when a worn thing goes; a Log card's Next / Prev page goes to the new page's top
--        and first line; a card opened in the other window takes the pad along (Focus.follow, the Admin tab's
--        openNext); the seat chooser and the seat pop-out give the pad back where it came from
--   265  the car dash's volume is a knob on the pad: A grabs, the D-pad turns it both ways, no wrap
--   266  the chat window's menu is a stop (Up from the tabs) and players 2-4 open chat on their own pads
--   267  Bug report is on every window's menu; the join screen answers Enter, Escape, the arrows and Tab
-- Run from the repo root: lua51 ZeDUI/tools/qa/pad_reach_fixes_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_reach_fixes_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(rel)
    local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/" .. rel, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end
-- a top-level function (its "end" at the start of a line)
local function fn(src, head)
    local pat = "\n" .. head:gsub("([%.%:%(%)%[%]%-])", "%%%1") .. ".-\nend\n"
    local body = src:match(pat)
    check("finds " .. head, body ~= nil)
    return body or ""
end
local function load(code, name)
    local chunk, err = loadstring(code, name)
    check("compiles " .. name, chunk ~= nil, err)
    return chunk
end

-- ===========================================================================
-- 264: the Journal delete question
-- ===========================================================================
do
    local src = readSrc("JournalTab.lua")
    local code = "local ZeD = ...\n" .. fn(src, "local function journalEntries(win)") .. fn(src, "function ZeD.JournalTab.confirmDelete(win)")
        .. fn(src, "function ZeD.JournalTab.cancelDelete(win)") .. fn(src, "function ZeD.JournalTab.land(win, elements)")
    local ZeD = { JournalTab = {} }
    local chunk = load(code, "journal")
    if chunk then chunk(ZeD) end
    local JT = ZeD.JournalTab
    local e1, e2, e3, e4 = { t = 1 }, { t = 2 }, { t = 3 }, { t = 4 }
    local md = { ZeD_Journal = { entries = { e1, e2, e3, e4 } } }
    local win = { _playerObj = { getModData = function() return md end } }
    -- the Log page's stops: the kills row, a tag, then one cross per entry, then Save (as _buildJournalSubContent)
    local function build()
        local els = { { id = "journal:kills" }, { id = "journal:tag:1" } }
        for i = 1, #md.ZeD_Journal.entries do els[#els + 1] = { id = "journal:del:" .. i, journalKind = "delete", entryIdx = i } end
        els[#els + 1] = { id = "journal:__save" }
        JT.land(win, els)
        return els
    end
    local function landed(els) return els._focusIdx and els[els._focusIdx].id or "nothing" end

    win._journalAsk = { entry = e2 }
    JT.cancelDelete(win)
    check("Cancel: the question is gone", win._journalAsk == nil)
    local els = build()
    check("Cancel: the pad goes back to the entry's cross", landed(els) == "journal:del:2", landed(els))
    check("the landing is used once", landed(build()) == "nothing", landed(build()))

    win._journalAsk = { entry = e2 }
    JT.confirmDelete(win)
    check("Delete removes the entry", #md.ZeD_Journal.entries == 3 and md.ZeD_Journal.entries[2] == e3)
    els = build()
    check("Delete: the pad lands on the next entry's cross (it took the place)", landed(els) == "journal:del:2", landed(els))

    win._journalAsk = { entry = e4 }
    JT.confirmDelete(win)
    els = build()
    check("Delete the last: the pad lands on the one before", landed(els) == "journal:del:2" and md.ZeD_Journal.entries[2] == e3, landed(els))

    -- the crosses not stamped on the first build after the question: tried again
    win._journalAsk = { entry = e1 }
    JT.cancelDelete(win)
    local bare = { { id = "journal:kills" } }
    JT.land(win, bare)
    check("no crosses yet: nothing lands, the landing waits", bare._focusIdx == nil and win._journalLand ~= nil)
    els = build()
    check("the next build lands on the entry", landed(els) == "journal:del:1", landed(els))

    -- the entry out of the pad's reach (only far ones are stops): the nearest cross
    win._journalAsk = { entry = e1 }
    JT.cancelDelete(win)
    local far = { { id = "journal:del:3", journalKind = "delete", entryIdx = 3 }, { id = "journal:del:2", journalKind = "delete", entryIdx = 2 } }
    JT.land(win, far)
    check("an entry out of reach: the nearest cross", far._focusIdx == 2, far._focusIdx)

    -- every entry gone: nothing to land on, no error
    md.ZeD_Journal.entries = { e1 }
    win._journalAsk = { entry = e1 }
    JT.confirmDelete(win)
    local none = { { id = "journal:kills" } }
    JT.land(win, none)
    check("the last entry deleted: the default landing", none._focusIdx == nil and win._journalLand == nil)
end

-- ===========================================================================
-- 264: the Equip tab after Unequip / Drop
-- ===========================================================================
do
    local src = readSrc("ZeD_CharacterWindow.lua")
    local block = src:match("\n(    local equipGone = nil\n.-)\n    %-%- after a Find clear")
    check("finds the Equip landing block", block ~= nil)
    local chunk = block and load("return function(win, elements, finding)\n" .. block .. "\nreturn elements\nend", "equip")
    local land = chunk and chunk() or function(_, e) return e end
    local function slot(t, filled) return { id = "equipslot:" .. t, slotType = t, item = filled and { t } or nil } end
    local function list(...)
        local out = { { id = "equipslot:__disclosure", slotType = "__disclosure" }, { id = "equipgroup:HEAD", slotType = "__group_HEAD" } }
        for _, t in ipairs({ ... }) do out[#out + 1] = slot(t, true) end
        return out
    end
    local function landed(els) return els._focusIdx and els[els._focusIdx].id or "nothing" end
    local win = {}
    land(win, list("Hat", "Shirt", "Pants", "Shoes"))
    check("the filled slots' order is kept", win._equipFilledOrder and #win._equipFilledOrder == 4)

    -- the card's Unequip: the card closes, its slot is already gone
    win._equipCardSeed = "Shirt"
    win._gpFocusedEquipSlot = "__card_unequip"
    local els = land(win, list("Hat", "Pants", "Shoes"))
    check("Unequip from the card: the next filled slot down", landed(els) == "equipslot:Pants", landed(els))
    check("and the tab knows it", win._gpFocusedEquipSlot == "Pants")

    -- the card closed while the action ran: back on the slot, then the slot empties
    win._equipCardSeed = "Shoes"
    els = land(win, list("Hat", "Pants", "Shoes"))
    check("back from a card on a slot still filled", landed(els) == "equipslot:Shoes", landed(els))
    els = land(win, list("Hat", "Pants"))
    check("the last slot empties under the pad: the one above", landed(els) == "equipslot:Pants", landed(els))

    -- nothing gone: no landing named (the focus stays by its id)
    els = land(win, list("Hat", "Pants"))
    check("nothing gone: no landing", els._focusIdx == nil)

    -- the doll: an emptied slot stays a stop, so the pad stays on it
    win._gpFocusedEquipSlot = "Hat"
    local doll = list("Pants")
    doll[#doll + 1] = slot("Hat", false)
    els = land(win, doll)
    check("the doll keeps the emptied slot: no jump", els._focusIdx == nil)

    -- the Find field holding text: its own landing, not this one
    win._gpFocusedEquipSlot = "Pants"
    els = land(win, list(), true)
    check("while finding: no landing", els._focusIdx == nil)

    -- on a group header or the disclosure: never treated as a slot
    win._gpFocusedEquipSlot = "__group_HEAD"
    els = land(win, list("Pants"))
    check("on a header: no landing", els._focusIdx == nil)
end

-- ===========================================================================
-- 264: a Log card's Next / Prev page
-- ===========================================================================
do
    local src = readSrc("ZeD_LogCards.lua")
    local pager = fn(src, "function P.pager(items, card, page)")
    local block = src:match("\n(        if card%.toTop and .-\n        end\n)")
    check("finds the new page's landing", block ~= nil)
    local P, F, Lm = {}, {}, { bump = function() end }
    local flowed = nil
    F.flow = function(items, list) flowed = list end
    local c1 = load("local P, F, Lm, tr = ...\n" .. pager, "pager")
    if c1 then c1(P, F, Lm, function(k) return k end) end
    local card = { page = 1 }
    P.pager({}, card, { page = 1, pages = 3 })
    local nextBtn = nil
    for _, b in ipairs(flowed or {}) do if b.id == "lnext" then nextBtn = b end end
    check("the pager has Next", nextBtn ~= nil)
    if nextBtn then nextBtn.run() end
    check("Next asks for page 2 and the top", card.page == 2 and card.toTop == true)
    local c2 = block and load("return function(win, st, card, page, rows, D)\n" .. block .. "\nend", "toTop")
    local go = c2 and c2() or function() end
    local scrolled, focused = nil, nil
    local st = { tk = { scroll = { setScrollPos = function(_, v) scrolled = v end } } }
    local D = { focusId = function(_, _, id) focused = id end }
    go(nil, st, card, { page = 1 }, { { s = 11 } }, D)
    check("the old page still showing: nothing moves yet", scrolled == nil and focused == nil and card.toTop)
    go(nil, st, card, { page = 2 }, { { s = 21 }, { s = 22 } }, D)
    check("page 2 here: the view to its top", scrolled == 0)
    check("and the pad on its first line", focused == "tk:l:21", focused)
    check("once", card.toTop == nil)
end

-- ===========================================================================
-- 264: a card in the other window takes the pad along (Focus.follow, AdminTab)
-- ===========================================================================
do
    local src = readSrc("Input/FocusManager.lua")
    local code = "local Focus, _pnOf, _st, _modeOf = ...\n" .. fn(src, "function Focus.follow(w, fromPad)")
    local Focus = {}
    local claimed = nil
    Focus.claimFocus = function(w) claimed = w end
    local st = {}
    local mode = "gamepad"
    local chunk = load(code, "follow")
    if chunk then chunk(Focus, function(w) return w.playerNum or 0 end, st, function() return mode end) end
    local charWin, worldWin = { playerNum = 0 }, { playerNum = 0 }
    st[0] = { win = worldWin }
    Focus.follow(charWin)
    check("the pad in the World window: it follows to the Character window's card", claimed == charWin)
    claimed = nil
    st[0].win = charWin
    Focus.follow(charWin)
    check("already there: nothing", claimed == nil)
    st[0].win = nil
    Focus.follow(charWin)
    check("no window holds the pad (the game has it): nothing", claimed == nil)
    Focus.follow(charWin, true)
    check("a pad press from the game (the world menu): it follows", claimed == charWin)
    claimed = nil
    mode = "kbm"
    st[0].win = worldWin
    Focus.follow(charWin)
    check("the mouse and keyboard: never", claimed == nil)

    local asrc = readSrc("AdminTab.lua")
    local acode = "local A, ZeD, TAB_ID = ...\n" .. fn(asrc, "function A.padFollow(w, fromPad)") .. fn(asrc, "function A.openNext(what, playerNum, fromPad)")
    local followed = nil
    local Z = { Input = { Focus = { follow = function(w, p) followed = { w = w, pad = p } end } } }
    ZeD_WorldWindow = { openTab = function() return true end, getWindow = function() return worldWin end }
    local A = { visible = function() return true end }
    local ac = load(acode, "admin")
    if ac then ac(A, Z, "admin") end
    check("openNext opens", A.openNext({ kind = "pstats" }, 0) == true)
    check("and the pad follows to the World window", followed and followed.w == worldWin and not followed.pad)
    A.openNext({ kind = "osafe" }, 0, true)
    check("from the world's menu: fromPad passed on", followed and followed.pad == true)
    ZeD_WorldWindow = nil
end

-- ===========================================================================
-- 264: the seat chooser and the seat pop-out give the pad back
-- ===========================================================================
do
    local fsrc = readSrc("Input/FocusManager.lua")
    local ssrc = readSrc("ZeD_SeatChooser.lua")
    local shown = {}
    local engine = {}
    JoypadState = { players = { {} } }
    getJoypadFocus = function(pn) return engine[pn] end
    setJoypadFocus = function(pn, c) engine[pn] = c end
    local reclaimed = nil
    local Focus = { reclaimEngineFocus = function(pn) reclaimed = pn end }
    local code = "local Focus, _shown, _pushEngineFocus = ...\n" .. fn(fsrc, "function Focus.menuClosed(menu, pn)")
    local chunk = load(code, "menuClosed")
    if chunk then chunk(Focus, function(ui) return shown[ui] == true end, function(c, pn) engine[pn or 0] = c end) end
    local S = {}
    local scode = "local S, ZeD = ...\n" .. fn(ssrc, "function S.padBack(self)") .. fn(ssrc, "function S.padFrom(w, pn)")
    local sc = load(scode, "seats")
    if sc then sc(S, { Input = { Focus = Focus } }) end

    local dash, chooser = { name = "radio" }, { name = "chooser", playerNum = 0 }   -- (dash: first a panel of its own, the car radio; then a ZeD window)
    shown[dash] = true
    JoypadState.players[1].focus = dash
    engine[0] = dash
    S.padFrom(chooser, 0)
    JoypadState.players[1].focus = chooser
    engine[0] = chooser
    check("the chooser keeps what held the pad", chooser.origin == dash)
    S.padBack(chooser)
    check("closed: the pad goes back to the panel that held it", engine[0] == dash, engine[0] and engine[0].name)

    -- opened from the game (the vehicle wheel, gone by now): the pad goes to the game, a ZeD window asked to take it
    local wheel = { name = "wheel" }
    JoypadState.players[1].focus = wheel
    S.padFrom(chooser, 0)
    engine[0] = chooser
    reclaimed = nil
    S.padBack(chooser)
    check("opened from the wheel: the pad leaves the chooser", engine[0] == nil)
    check("and a ZeD window that held it gets it back", reclaimed == 0)

    -- a ZeD window held it (the dash on ZeD's focus): ZeD's focus gives it back, so a dash that let go keeps nothing
    Focus.getFocusedWindow = function() return dash end
    JoypadState.players[1].focus = dash
    S.padFrom(chooser, 0)
    check("a ZeD window: no origin kept, ZeD's focus answers", chooser.origin == nil)
    engine[0] = chooser
    reclaimed = nil
    S.padBack(chooser)
    check("closed: ZeD's focus takes the pad back", reclaimed == 0 and engine[0] == nil)
    Focus.getFocusedWindow = nil

    -- no pad: nothing
    JoypadState.players[1] = nil
    engine[0] = chooser
    S.padBack(chooser)
    check("no pad on the player: nothing moves", engine[0] == chooser)
    JoypadState, getJoypadFocus, setJoypadFocus = nil, nil, nil
end

-- ===========================================================================
-- 265: the car dash's volume knob
-- ===========================================================================
do
    local fsrc = readSrc("Input/FocusManager.lua")
    local dsrc = readSrc("ZeD_Dashboard.lua")
    local Focus = { knobPrompts = function() return {} end }
    local fc = load("local Focus, ZeD = ...\n" .. fn(fsrc, "function Focus.knobStop(el, turn, opts)") .. fn(fsrc, "function Focus.knobGrabbed(holder, id)"), "knob")
    local Z = { tr = function(k) return k end }
    Z.Input = { Focus = Focus }
    if fc then fc(Focus, Z) end
    local steps = {}
    local RO = { volStep = function(chr, part, d, wrap) steps[#steps + 1] = { d = d, wrap = wrap } end }
    ZeD_Dashboard = {}
    getSpecificPlayer = function() return {} end
    getGameSpeed = function() return 1 end
    local dc = load("local ZeD, RO, ROCKER, _promptKey = ...\n" .. fn(dsrc, "function ZeD_Dashboard:_volKnob(el, st)"), "dash")
    if dc then dc(Z, RO, { makeshift = true }, function(id, st) return (id == "pwr") and "UI_ZeD_Dash_PromptRadioOn" or "x" end) end
    local fired = {}
    local dash = setmetatable({ _pad = true, playerNum = 0, _driver = true, _st = { radioPart = "part" } }, { __index = ZeD_Dashboard })
    dash._fire = function(self, id, sec) fired[#fired + 1] = id end
    local released = false
    local function newEl()
        return { id = "dash:vol", onActivate = function() fired[#fired + 1] = "vol" end, onContextMenu = function() fired[#fired + 1] = "vol2" end,
                 onCancel = function() released = true end }
    end
    local st = { radio = { kind = "car" } }
    local el = newEl()
    dash:_volKnob(el, st)
    check("not held: A says Grab", el.promptA == "UI_ZeD_Prompt_KnobGrab", el.promptA)
    check("X says the power", el.promptX == "UI_ZeD_Dash_PromptRadioOn", el.promptX)
    check("not held: the D-pad moves on", el.onDpadDir(dash, el, "left") == false and #steps == 0)
    el.onActivate(dash, el)
    check("A grabs", Focus.knobGrabbed(dash, "dash:vol"))
    el = newEl()
    dash:_volKnob(el, st)   -- (the next frame's stop)
    check("held: A says Let go, B too", el.promptA == "UI_ZeD_Prompt_KnobLetGo" and el.promptBWord == "UI_ZeD_Prompt_KnobLetGo")
    el.onDpadDir(dash, el, "down")
    el.onDpadDir(dash, el, "left")
    el.onDpadDir(dash, el, "right")
    check("Down / Left turn it down, Right up", #steps == 3 and steps[1].d == -1 and steps[2].d == -1 and steps[3].d == 1)
    check("never wrapping", steps[1].wrap == false and steps[3].wrap == false)
    check("B lets go, the dash stays", el.onCancel(dash, el) == true and not released and not Focus.knobGrabbed(dash, "dash:vol"))
    el.onCancel(dash, el)
    check("B again: leaves the dash", released)
    el.onContextMenu(dash, el)
    check("X pushes it: the power", fired[#fired] == "pwr")
    local rel = newEl()
    dash:_volKnob(rel, { radio = { kind = "makeshift" } })
    check("a rocker set: X has nothing (its rocker is the power)", rel.onContextMenu == nil and rel.promptX == nil)
    ZeD_Dashboard, getSpecificPlayer, getGameSpeed = nil, nil, nil
end

-- ===========================================================================
-- 266: chat's menu by pad; players 2-4 open chat
-- ===========================================================================
do
    local src = readSrc("ZeD_Chat.lua")
    local code = "local C, U, px, ZeD, tr = ...\n" .. fn(src, "function ZeD_ChatWindow:onJoypadDown(button, jd)")
        .. fn(src, "function ZeD_ChatWindow:_padStep(dir)") .. fn(src, "function C.open(typing, pad)")
    ZeD_ChatWindow = {}
    Joypad = { AButton = 1, BButton = 2 }
    local engine = {}
    JoypadState = { players = { {}, {}, {} } }
    updateJoypadFocus = function(jd) jd.updated = true end
    setJoypadFocus = function(pn, c) engine[pn] = c end
    getTimestampMs = function() return 0 end
    local C = { active = function() return true end, tabsShown = function() return { { id = "general" } } end, tab = "general" }
    local Z = { TM = { getFontHeight = function() return 10 end }, T = { fontF2 = 1 }, uiSound = function() end }
    local menuOpened = nil
    Z.WindowMenu = {}
    local chunk = load(code, "chat")
    if chunk then chunk(C, { LINE_GAP = 2 }, function(n) return n end, Z, function(k) return k end) end
    local win = setmetatable({ playerNum = 0, zone = "tabs", scroll = 0, input = {} }, { __index = ZeD_ChatWindow })
    win.windowBoxRect = function() return { x = 1, y = 1, w = 8, h = 8 } end
    win.openWindowMenu = function(self) menuOpened = self; Z.WindowMenu.current = { win = self } end
    win.pickTab = function() end
    win:_padStep("up")
    check("Up from the tabs: the window box", win.zone == "box")
    win:_padStep("left")
    check("Left / Right stay on it", win.zone == "box")
    win:onJoypadDown(Joypad.AButton, {})
    check("A opens the window's menu (Name color, Theme, Accent)", menuOpened == win)
    check("and the menu gives the pad back to chat", Z.WindowMenu.current.origin == win)
    win:_padStep("down")
    check("Down: back to the tabs", win.zone == "tabs")

    C.win = win
    win.setVisible = function() end
    C.open(false, 2)
    check("player 3 opens chat: the window is theirs", win.playerNum == 2)
    check("on their own pad", JoypadState.players[3].focus == win and JoypadState.players[1].focus == nil)
    win.joyfocus = JoypadState.players[3]
    C.open(false, true)
    check("player 1 by pad after: theirs, player 3 let go", win.playerNum == 0 and JoypadState.players[1].focus == win and engine[2] == nil)
    win.focusInput = function() end
    win.playerNum = 2
    C.open(true)
    check("the chat key (the keyboard): player 1's", win.playerNum == 0 and win.zone == "input")
    ZeD_ChatWindow, Joypad, JoypadState, updateJoypadFocus, setJoypadFocus, getTimestampMs = nil, nil, nil, nil, nil, nil
end

-- ===========================================================================
-- 267: Bug report on every window's menu
-- ===========================================================================
do
    local src = readSrc("ZeD_WindowMenu.lua")
    local code = "local WM, ZeD, tr = ...\n" .. fn(src, "local function setTheme(base, accent, size, pn)")
        .. fn(src, "local function leaf(name, fire, checked, category)") .. fn(src, "function WM.build(win)")
    local copied = nil
    local Z = { Settings = { baseKeys = {}, baseLabels = {}, accentKeys = {}, accentLabels = {}, sizeKeys = {}, sizeLabels = {} },
                Messages = { copyBugReport = function(pn) copied = pn end } }
    local WM = {}
    local chunk = load(code, "windowmenu")
    if chunk then chunk(WM, Z, function(k) return k end) end
    local items = WM.build and WM.build({ noResetControl = true, playerNum = 1 }) or {}
    local bug, at, setupAt = nil, nil, nil
    for i, it in ipairs(items) do
        if it.name == "UI_ZeD_Msg_BugReport" then bug, at = it, i end
        if it.name == "UI_ZeD_WinMenu_Setup" then setupAt = i end
    end
    check("the window menu has Bug report", bug ~= nil)
    -- (KISS #40: ZeD setup is near the top now; Bug report is the last row without a pad)
    check("the last row without a pad, ZeD setup above it near the top", at and setupAt and at == #items and setupAt < at)
    if bug then bug.onFire() end
    check("it copies the caught errors for the window's player", copied == 1)
end

-- ===========================================================================
-- 267: the join screen's keys
-- ===========================================================================
do
    local src = readSrc("ZeD_CommunityCards.lua")
    local block = src:match("\n(    local JOIN_KEYS = nil\n.-\n    function ZeD_JoinWindow:onKeyPress%(key%)\n.-\n    end\n)")
    check("finds the join screen's keys", block ~= nil)
    Keyboard = { KEY_RETURN = 28, KEY_NUMPADENTER = 156, KEY_ESCAPE = 1, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_TAB = 15, KEY_UP = 200,
                 KEY_DOWN = 208, KEY_PRIOR = 201, KEY_NEXT = 209, KEY_SPACE = 57 }
    ZeD_JoinWindow = {}
    local chunk = block and load(block, "join")
    if chunk then chunk() end
    local pressed, scrolled = {}, {}
    local w = setmetatable({ pick = "agree", getMouseX = function() return 5 end, getMouseY = function() return 5 end }, { __index = ZeD_JoinWindow })
    w.press = function(self, id) pressed[#pressed + 1] = id end
    w.padScroll = function(self, d) scrolled[#scrolled + 1] = d end
    check("takes Enter and Escape", w:isKeyConsumed(Keyboard.KEY_RETURN) and w:isKeyConsumed(Keyboard.KEY_ESCAPE))
    check("leaves other keys to the game", not w:isKeyConsumed(30))
    w:onKeyPress(Keyboard.KEY_RETURN)
    check("Enter presses I agree (the picked answer)", pressed[1] == "agree")
    w:onKeyPress(Keyboard.KEY_ESCAPE)
    check("Escape picks Leave, pressing nothing", w.pick == "leave" and #pressed == 1)
    check("the pick shows for the keyboard", w._keyPick ~= nil)
    w:onKeyPress(Keyboard.KEY_RETURN)
    check("then Enter leaves", pressed[2] == "leave")
    w:onKeyPress(Keyboard.KEY_TAB)
    check("Tab moves to the other answer", w.pick == "agree")
    w:onKeyPress(Keyboard.KEY_UP)
    w:onKeyPress(Keyboard.KEY_NEXT)
    check("Up and Page Down scroll", scrolled[1] == -1 and scrolled[2] == 4)
    w.done = true
    check("answered: it takes no keys", not w:isKeyConsumed(Keyboard.KEY_RETURN))
    Keyboard, ZeD_JoinWindow = nil, nil
end

print("pad_reach_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
