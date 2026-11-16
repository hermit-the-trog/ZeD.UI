-- ZeDUI/tools/qa/pad_type_sim.lua
-- (Nov 16 2026, QA's audit, punch list 252 / 254 / 261) Text boxes the controller could not type in, the Journal's
-- "Into notebook" picker, and B on "Keep these display settings?". Runs the real code, cut from the files, with stubs:
--   ZeD_Keyboard.lua      KB.edit (the one "A on a text box"), with the keyboard's own accept / hide
--   ZeD_MainMenuSaves.lua typeIn / fieldStop (the menus' field stops)
--   CraftingCore.lua      CC.buildFocusables: the search stop after the header's selects (Craft, Build, Recipes)
--   JournalTab.lua        the header's search stop (after the page tabs)
--   ZeD_JournalReaders.lua the Into picker's stop
--   ZeD_MainMenuOptions.lua joyB / joyDir / joyA / back / update / setConfirm on the monitor question
-- Run from the repo root: lua51 ZeDUI/tools/qa/pad_type_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_type_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("pad_type_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed == 0 and 0 or 1)
end

local function readSrc(rel)
    local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/" .. rel, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end
-- a top-level function's text: from "\nfunction <name>(" to its closing "\nend\n"
local function cut(src, name, what)
    local pat = "\n" .. name:gsub("[%.%:%(%)]", "%%%0") .. ".-\nend\n"
    local body = src:match(pat)
    check("finds " .. (what or name), body ~= nil)
    if not body then done() end
    return body
end

-- ---------------------------------------------------------------------------
-- stubs shared by every part
-- ---------------------------------------------------------------------------
local function newEntry(text)
    local e = { javaObject = {}, _text = text or "", _focused = false, focusCalls = 0 }
    function e:focus() self._focused = true; self.focusCalls = self.focusCalls + 1 end
    function e:unfocus() self._focused = false end
    function e:isFocused() return self._focused end
    function e:getText() return self._text end
    function e:getInternalText() return self._text end
    function e:setText(t) self._text = t end
    e.javaObject.onTextChange = function() end
    return e
end

local kbSrc = readSrc("ZeD_Keyboard.lua")
local KB = {}
ZeD = { Keyboard = KB, tr = function(k) return k end }
updateJoypadFocus = function() end
getSpecificPlayer = function() return nil end

-- the keyboard object: its real accept / hide on a small stub panel
ZeD_Keyboard = {}
local kbMethods = cut(kbSrc, "function ZeD_Keyboard:accept()", "ZeD_Keyboard:accept")
    .. cut(kbSrc, "function ZeD_Keyboard:hide()", "ZeD_Keyboard:hide")
assert(loadstring(kbMethods))()
local kb = setmetatable({}, { __index = ZeD_Keyboard })
function kb:setVisible() end
function kb:removeFromUIManager() end

-- vanilla's API as Overrides/Prompts.lua points it at ZeD's keyboard: it takes the pad and remembers who had it
OnScreenKeyboard = { Show = function(pn, e, jd)
    kb.playerNum, kb.textEntryBox, kb.joypadData = pn, e, jd
    kb.onAccept, kb.onCancel = nil, nil
    e:focus()
    kb._zedPrev = jd and jd.focus or nil
    if jd and jd.focus ~= kb then kb.prevFocus = jd.focus; jd.focus = kb end
    kb.shownFor = pn
    return kb
end }

-- KB.entryOf and KB.edit, as written
local editBody = kbSrc:match("\nfunction KB%.entryOf%(.-\nZeD%.padType = KB%.edit\n")
check("finds KB.entryOf .. KB.edit", editBody ~= nil)
if not editBody then done() end
assert(loadstring("local KB = ...\n" .. editBody))(KB)

-- ---------------------------------------------------------------------------
-- 1. KB.edit: A opens the keyboard, closing it gives the pad back and the caret goes
-- ---------------------------------------------------------------------------
do
    local win = { name = "Character window" }
    local jd = { focus = win, player = 0 }
    JoypadState = { players = { jd } }
    local search = { input = newEntry("") }   -- a ZeD_SearchField
    check("entryOf: a search field's box is its input", KB.entryOf(search) == search.input)
    local note = { _entry = newEntry("") }    -- a ZeD_TextEntry
    check("entryOf: a text entry's box is its _entry", KB.entryOf(note) == note._entry)
    local plain = newEntry("")
    check("entryOf: a plain box is itself", KB.entryOf(plain) == plain)

    local opened = KB.edit(search, 0)
    check("A on the box opens the keyboard", opened == true and kb.textEntryBox == search.input)
    check("the keyboard holds the pad", jd.focus == kb)
    check("the box has the caret while typing", search.input:isFocused())
    search.input:setText("can")
    kb:accept()   -- RT, or B (the keyboard's B is Back: it keeps the text)
    check("closing the keyboard gives the pad back to the window (hand on the box)", jd.focus == win, jd.focus and jd.focus.name)
    check("the typed text stays", search.input:getText() == "can")
    check("the box lets go of the game's keyboard after", not search.input:isFocused())

    local heard = nil
    KB.edit(note, 0, { onAccept = function(e) heard = e end })
    kb:accept()
    check("onAccept hears the box after the keyboard closes", heard == note._entry)
    KB.edit(note, 0, { keepCaret = true })
    kb:accept()
    check("keepCaret: the box keeps the caret", note._entry:isFocused())
    note._entry:unfocus()

    -- the main menu's own controller (opts.jd), on another player number
    local mmScreen = { name = "MainScreen" }
    local mjd = { focus = mmScreen, player = 2 }
    KB.edit(plain, 0, { jd = mjd })
    check("the menu's controller is the one the keyboard takes", mjd.focus == kb and kb.shownFor == 2, kb.shownFor)
    kb:accept()
    check("and it goes back to the menu", mjd.focus == mmScreen)

    -- no keyboard to open: a click's caret instead
    local saved = OnScreenKeyboard
    OnScreenKeyboard = nil
    local e2 = newEntry("")
    check("no keyboard: edit says so", KB.edit(e2, 0) == false)
    check("no keyboard: the box takes the caret", e2:isFocused())
    OnScreenKeyboard = saved
    check("a nil box is left alone", KB.edit(nil, 0) == false)
end

-- ---------------------------------------------------------------------------
-- 2. the menus: typeIn / fieldStop (ZeD_MainMenuSaves.lua)
-- ---------------------------------------------------------------------------
do
    local sv = readSrc("ZeD_MainMenuSaves.lua")
    local block = sv:match("\nlocal function typeIn%(.-\nlocal function fieldStop%(.-\nend\n")
    check("finds typeIn and fieldStop", block ~= nil)
    if not block then done() end
    local pad = true
    local marks = 0
    local mmScreen = { name = "MainScreen" }
    local mjd = { focus = mmScreen, player = 0 }
    MM = { gamepad = function() return pad end, joypad = function() return mjd end, focusOpts = function(w) return { win = w } end }
    ZeD.Focus = { mark = function() marks = marks + 1 end }
    local get = assert(loadstring("local MM = ...\n" .. block .. "\nreturn typeIn, fieldStop"))
    local typeIn, fieldStop = get(MM)

    local win = { _specs = {}, focusId = nil }
    local find = newEntry("")
    local sp = fieldStop(win, find, "field:find", 10, 20, 200, 24, 999)
    check("a field is a stop with its place", win._specs[1] == sp and sp.x == 10 and sp.w == 200 and sp.noDraw)
    check("no mark while the hand is elsewhere", marks == 0)
    win.focusId = "field:find"
    fieldStop(win, find, "field:find", 10, 20, 200, 24, 999)
    check("the hand on it: the controller's mark", marks == 1)
    sp.fn()
    check("A on the stop opens the keyboard on the field", kb.textEntryBox == find and mjd.focus == kb)
    kb:accept()
    check("closing it: the menu has the pad again, hand still on the field", mjd.focus == mmScreen and win.focusId == "field:find")

    -- Return-only fields (a map folder to add): the keyboard's close adds what was typed, never an empty one
    local added = 0
    local other = newEntry("")
    other.onCommandEntered = function() added = added + 1 end
    local osp = fieldStop({ _specs = {} }, other, "field:other", 0, 0, 100, 24, 700, 1, { submit = true })
    osp.fn()
    kb:accept()
    check("submit: nothing typed, nothing added", added == 0)
    osp.fn()
    other:setText("Muldraugh, KY")
    kb:accept()
    check("submit: the typed folder is added as Return adds it", added == 1)

    -- with the mouse, A's spec gives the caret (the click path)
    pad = false
    local m = newEntry("")
    typeIn(m)
    check("with the mouse: the field takes the caret, no keyboard", m:isFocused() and kb.textEntryBox ~= m)
    pad = true
end

-- ---------------------------------------------------------------------------
-- 3. Craft / Build / Recipes: the search stop (CraftingCore)
-- ---------------------------------------------------------------------------
do
    local cc = readSrc("CraftingCore.lua")
    local body = cut(cc, "function CC.buildFocusables(", "CC.buildFocusables")
    local CC = {}
    local stubRows = function() return { { id = "list" } } end
    assert(loadstring("local CC, catRowFocusables, popRowFocusables = ...\n" .. body))(CC, stubRows, stubRows)
    ZeD.T = { px = function(v) return v end }
    ZeD.Stations = nil
    local field = { isVisible = function() return true end, input = newEntry("") }
    local state = {
        zones = {
            { type = "stationDropdown", x = 6, y = 30, w = 120, h = 24 },
            { type = "catDropdown", x = 132, y = 30, w = 120, h = 24 },
            { type = "recipeRow", id = "Base.Plank", x = 0, y = 60, w = 400, h = 20 },
        },
        _searchField = field, _searchRect = { x = 258, y = 30, w = 140, h = 24 },
    }
    local edited = nil
    KB.edit = function(box, pn) edited = box; return true end
    local win = { _playerObj = { getPlayerNum = function() return 0 end } }
    local els = CC.buildFocusables(win, state, "craft", "ZeD_CraftPins", function() end)
    local order = {}
    for i, e in ipairs(els) do order[i] = e.id end
    check("Craft: the search is a stop", els[3] and els[3].id == "craft:search", table.concat(order, ","))
    check("Craft: it comes after the station and category selects (landing unchanged)", els[1].id == "craft:stDrop" and els[2].id == "craft:catDrop")
    check("Craft: its prompt says Type", els[3] and els[3].promptA == "UI_ZeD_Inv_PromptType")
    if els[3] then els[3].onActivate(win, els[3]) end
    check("Craft: A opens the keyboard on the search", edited == field)

    -- Recipes (read only): the Category select is in the band, below: the search goes first of the page's stops
    local jstate = {
        zones = { { type = "recipeRow", id = "Base.Plank", x = 0, y = 60, w = 400, h = 20 },
                  { type = "catDropdown", x = 6, y = 400, w = 120, h = 24 } },
        _searchField = field, _searchRect = { x = 200, y = 4, w = 180, h = 24 },
    }
    local jels = CC.buildFocusables(win, jstate, "jrecipe", nil, nil)
    check("Recipes: the search is the page's first stop", jels[1] and jels[1].id == "jrecipe:search", jels[1] and jels[1].id)

    -- hidden (no field shown): no stop
    local hidden = { isVisible = function() return false end }
    local hstate = { zones = {}, _searchField = hidden, _searchRect = { x = 0, y = 0, w = 10, h = 10 } }
    check("a hidden search is not a stop", #CC.buildFocusables(win, hstate, "build", nil, nil) == 0)
end

-- ---------------------------------------------------------------------------
-- 4. the Journal's header: the page's search after the page tabs; 5. the Into picker
-- ---------------------------------------------------------------------------
do
    local jt = readSrc("JournalTab.lua")
    local block = jt:match("\nlocal function tabActivate%(.-\nfunction ZeD%.JournalTab%.headerFocusables%(.-\nend\n")
    check("finds the Journal header's stops", block ~= nil)
    if not block then done() end
    ZeD.JournalTab = {}
    assert(loadstring(block))()
    local edited = nil
    KB.edit = function(box, pn) edited = box; return true end
    local field = { isVisible = function() return true end }
    local win = { _journalSubTab = 1, _playerObj = { getPlayerNum = function() return 0 end },
        _journalTabZones = { { x = 0, y = 30, w = 60, h = 20, page = 1 }, { x = 60, y = 30, w = 60, h = 20, page = 2 } },
        _journalFindZone = { x = 200, y = 4, w = 180, h = 24, field = field } }
    local els = ZeD.JournalTab.headerFocusables(win)
    check("the page tabs first (landing on the tab unchanged)", els[1].id == "jtab:1" and els[2].id == "jtab:2")
    check("then the page's search", els[3] and els[3].id == "journal:__find")
    if els[3] then els[3].onActivate(win, els[3]) end
    check("A on the search opens the keyboard on it", edited == field)
    win._journalSubTab = 4
    els = ZeD.JournalTab.headerFocusables(win)
    check("Recipes: its search is CraftingCore's stop, not the header's", #els == 2)

    local jr = readSrc("ZeD_JournalReaders.lua")
    local iblock = jr:match("\nlocal function intoZone%(.-\nfunction J%.intoFocusable%(.-\nend\n")
    check("finds the Into picker's stop", iblock ~= nil)
    if not iblock then done() end
    local J = {}
    assert(loadstring("local J = ...\n" .. iblock))(J)
    local w2 = { _jrZones = {} }
    check("no notebook carried: no Into stop", J.intoFocusable(w2) == nil)
    local picked = {}
    w2._jrZones = { { id = "book:1", x = 0, y = 0, w = 10, h = 10, fn = function() end },
                    { id = "into", x = 8, y = 120, w = 140, h = 22, fn = function() picked[#picked + 1] = "first" end } }
    local el = J.intoFocusable(w2)
    check("a notebook carried: Into is a stop where it is drawn", el and el.id == "jr:into" and el.y == 120)
    -- the next frame draws it again with a new closure (the notebook picked now): A must use that one
    w2._jrZones[2].fn = function() picked[#picked + 1] = "second" end
    el.onActivate(w2, el)
    check("A steps Into with this frame's picker, not the frame the stop was built in", picked[1] == "second", picked[1])
end

-- ---------------------------------------------------------------------------
-- 6. "Keep these display settings?" (punch list 261)
-- ---------------------------------------------------------------------------
do
    local op = readSrc("ZeD_MainMenuOptions.lua")
    local safe = op:match("\nlocal SAFE_ANSWER = %b{}\n")
    check("finds the Options questions' safe answers", safe ~= nil)
    if not safe then done() end
    local src = safe .. cut(op, "function ZeD_MMOptions:setConfirm(", "ZeD_MMOptions:setConfirm")
        .. cut(op, "function ZeD_MMOptions:back()", "ZeD_MMOptions:back")
        .. cut(op, "function ZeD_MMOptions:joyA()", "ZeD_MMOptions:joyA")
        .. cut(op, "function ZeD_MMOptions:joyDir(", "ZeD_MMOptions:joyDir")
        .. cut(op, "function ZeD_MMOptions:joyB()", "ZeD_MMOptions:joyB")
        .. cut(op, "function ZeD_MMOptions:update()", "ZeD_MMOptions:update")
        .. cut(op, "function ZeD_MMOptions:finish()", "ZeD_MMOptions:finish")
    local now = 1000
    local baseA, baseDirTo = 0, nil
    MM = { now = function() return now end, clickSound = function() end, ctx = {}, pauseView = nil,
           showView = function() end }
    ZeD_MMWindow = {
        joyA = function() baseA = baseA + 1 end,
        joyDir = function(self, dir) if baseDirTo then self.focusId = baseDirTo end; if dir == "up" then self._edge = "up" end end,
        update = function() end,
    }
    ZeD_MMOptions = {}
    ZeD.MouseTick = { down = function() return false end }
    JoypadState = { players = {} }
    MainOptions = { loadKeys = function() end }
    getMouseX, getMouseY = function() return 0 end, function() return 0 end
    assert(loadstring("local MM, PALETTE = ...\n" .. src))(MM, {})
    local answers = {}
    local o = setmetatable({ confirm = false, focusId = "row:3", inGame = false,
        field = { setVisible = function() end, isFocused = function() return false end, unfocus = function() end },
        find = { isFocused = function() return false end, unfocus = function() end },
        isVisible = function() return true end,
        stopCapture = function() end, anyChanged = function() return false end,
    }, { __index = ZeD_MMOptions })
    function o:answerMonitor(keep) answers[#answers + 1] = keep; self:setConfirm(false) end
    local function ask() o._monitorUntil = now + 20000; o:setConfirm("monitor") end

    ask()
    check("the question lands on Cancel (the old settings)", o.focusId == "confirm:no", o.focusId)
    o:joyB()
    check("B answers No, as Escape does", answers[1] == false and o.confirm == false, tostring(answers[1]))

    ask()
    o:back()
    check("Back while it is up answers No (no skipping it)", answers[2] == false and o.confirm == false)

    ask()
    baseDirTo = "row:2"
    o:joyDir("up")
    check("Up can't leave the answers for an option row", o.focusId == "confirm:no", o.focusId)
    check("nor off the window's edge to the menu bar", o._edge == nil)
    baseDirTo = "confirm:yes"
    o:joyDir("right")
    check("Left / Right move between the answers", o.focusId == "confirm:yes")
    baseDirTo = nil
    o.focusId = "row:2"
    o:joyA()
    check("A off the answers presses nothing", baseA == 0 and o.focusId == "confirm:no")
    o:joyA()
    check("A on an answer presses it", baseA == 1)

    now = now + 19000
    o:update()
    check("19 s in: still asking", o.confirm == "monitor")
    now = now + 1500
    o:update()
    check("20 s in: the old settings come back even with the band not drawn", answers[3] == false and o.confirm == false)

    ask()
    o:finish()
    check("the window closing while it is up answers No", answers[4] == false)
end

done()
