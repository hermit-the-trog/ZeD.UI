-- ZeDUI/tools/qa/code_flags_sim.lua  (Nov 8 2026): the fixes from the comment pass's code flags (docs/plans/CODE_FLAGS_20261108.md),
-- each run on the real file with no game, each a check that fails on the code before the fix:
--   the Mods screen's wheel wrap: run twice (a reload), it wraps the wheel under it once, not its own last wrapper
--   the context menu override: loaded twice, every hook still wraps vanilla's function once
--   the radio display's marquee (ZeD_Plate.lua): no % on the ms clock (Kahlua gets it wrong past 2^31), and it still marches
--   the desk Mail's Put in Outbox: a letter the store refuses says the store's reason, not always "Outbox full"
--   the test window's F6: only in debug builds
--   the controller map: A leaves it open, B closes it (the foot offers only B)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/code_flags_sim.lua
-- It prints FAIL lines and a last line "code_flags_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]code_flags_sim%.lua$", "")
local LUA = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function readAll(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text of a block: from the line that starts with `head` to the first line that is just "end" after it
local function block(src, head)
    local a = string.find(src, "\n" .. head, 1, true)
    if not a then return nil end
    local b = string.find(src, "\nend\n", a + 1, true)
    return b and string.sub(src, a + 1, b + 4) or nil
end

local realRequire = require
require = function() end

-- ---------------------------------------------------------------------------
section("the Mods screen's wheel wrap, run again")
do
    local src = readAll(LUA .. "ZeD_MainMenuMods.lua")
    local a = string.find(src, "\n-- the wheel goes to whichever list view is up", 1, true)
    local wrap = a and block(string.sub(src, a), "function MM.wheel(del)")
    local pre = a and string.sub(src, a, (string.find(src, "\nfunction MM.wheel(del)", a, true)))
    check("the wrap is found in ZeD_MainMenuMods.lua", wrap ~= nil and pre ~= nil)
    if wrap and pre then
        local chunk = "local MM = ...\n" .. pre .. wrap
        local reads, base = 0, 0
        local MM = setmetatable({}, { __index = function(t, k) if k == "view" then reads = reads + 1 end; return nil end })
        rawset(MM, "wheel", function() base = base + 1; return false end)
        assert(loadstring(chunk))(MM)
        assert(loadstring(chunk))(MM)     -- a reload of the file
        MM.wheel(1)
        check("after a reload the wheel passes one Mods wrapper, not two", reads == 1, reads)
        check("and reaches the wheel under it once", base == 1, base)
    end
end

-- ---------------------------------------------------------------------------
section("the context menu override, loaded twice")
do
    local calls = {}
    local function vanilla(name) return function() calls[name] = (calls[name] or 0) + 1; return { options = {} } end end
    ISContextMenu = { get = vanilla("get"), clear = vanilla("clear"), prerender = vanilla("prerender"), render = vanilla("render") }
    ISWorldObjectContextMenu = { createMenu = vanilla("world") }
    ISInventoryPaneContextMenu = { createMenu = vanilla("inv") }
    local safeAsks = 0
    ZeD = { Safe = { on = function() safeAsks = safeAsks + 1; return true end } }
    local f = LUA .. "Overrides/ContextMenu.lua"
    assert(loadfile(f))()
    assert(loadfile(f))()             -- a reload
    local function one(name, fn)
        safeAsks, calls = 0, {}
        fn()
        check("after a reload " .. name .. " is wrapped once", safeAsks == 1, safeAsks)
        check("and reaches vanilla's " .. name .. " once", (calls[name] or 0) == 1, calls[name])
    end
    one("get", function() ISContextMenu.get(0, 10, 20) end)
    one("prerender", function() ISContextMenu.prerender({}) end)
    one("render", function() ISContextMenu.render({}) end)
    one("world", function() ISWorldObjectContextMenu.createMenu(0, {}, 1, 2, false) end)
    one("inv", function() ISInventoryPaneContextMenu.createMenu(0, true, {}, 1, 2) end)
    -- clear has no safe-mode test: a second wrapper would reach the first, then vanilla, still once; read its capture instead
    calls = {}
    local menu = {}
    ISContextMenu.clear(menu)
    check("clear reaches vanilla's once", calls.clear == 1, calls.clear)
    check("the vanilla functions are kept on the class", ISContextMenu._zedVanilla and ISContextMenu._zedVanilla.get ~= ISContextMenu.get)
    ISContextMenu, ISWorldObjectContextMenu, ISInventoryPaneContextMenu, ZeD = nil, nil, nil, nil
end

-- ---------------------------------------------------------------------------
section("the radio display's marquee")
do
    local src = readAll(LUA .. "ZeD_Plate.lua")
    local cs = block(src, "local function clockStep(t, ms, m)")
    local mq = block(src, "local function marquee(str, n, now)")
    check("clockStep and marquee are found in ZeD_Plate.lua", cs ~= nil and mq ~= nil)
    if cs and mq then
        local code = string.gsub(mq, "%-%-[^\n]*", "")
        check("marquee uses no % (the ms clock is past 2^31: Kahlua's % is wrong there)", not string.find(code, "%", 1, true))
        local marquee = assert(loadstring(cs .. mq .. "return marquee"))()
        local base = 320 * 5000000000                     -- a step count far past 2^31 (a multiple of the loop below)
        check("a short line stays as it is", marquee("ABC", 5, base) == "ABC")
        check("a long line starts at its first letter", marquee("ABCDE", 3, base) == "ABC", marquee("ABCDE", 3, base))
        check("one step on, one letter on", marquee("ABCDE", 3, base + 320) == "BCD", marquee("ABCDE", 3, base + 320))
        check("past the end it wraps through the gap", marquee("ABCDE", 3, base + 320 * 4) == "E  ", marquee("ABCDE", 3, base + 320 * 4))
        check("a whole loop on, back at the start", marquee("ABCDE", 3, base + 320 * 8) == "ABC", marquee("ABCDE", 3, base + 320 * 8))
    end
end

-- ---------------------------------------------------------------------------
section("the desk Mail: a letter the store refuses")
do
    require = realRequire
    local D = dofile(ROOT .. "ZeDUI/tools/qa/desk_stub.lua")
    D.boot(ROOT, true)
    local MM, MS = ZeD.MainMenu, ZeD.MailStore
    local root = D.buildDesk()
    root.icons:open("mail")
    D.frame()
    local mw = root.mailWin
    check("the Mail window opens", mw ~= nil)
    if mw then
        local realQueue = MS.queue
        mw.box = function() return { server = "Test Server" } end
        mw.putWhy = function() return nil end      -- the window's own test passes; the store says no
        local function tryWith(err)
            MS.queue = function() return nil, err end
            mw.note = nil
            mw:put()
            return mw.note
        end
        check("the store's 'to': the name is wanted", tryWith("to") == "UI_ZeD_Mail_NeedTo", mw.note)
        check("the store's 'subj': the subject is too long", string.find(tryWith("subj") or "", "UI_ZeD_Mail_SubjLong", 1, true) == 1, mw.note)
        mw.textEntry:setText("")
        check("the store's 'text', nothing written: words are wanted", tryWith("text") == "UI_ZeD_Mail_NeedText", mw.note)
        mw.textEntry:setText(string.rep("x", 2001))
        check("the store's 'text', too much: too long", string.find(tryWith("text") or "", "UI_ZeD_Mail_TooLong", 1, true) == 1, mw.note)
        check("the store's 'full': the Outbox is full", string.find(tryWith("full") or "", "UI_ZeD_Mail_OutboxFull", 1, true) == 1, mw.note)
        MS.queue = realQueue
    end
    require = function() end
end

-- ---------------------------------------------------------------------------
section("the test window's F6")
do
    local handler, asked, dbg = nil, 0, false
    ZeD = ZeD or {}
    local keepIR = ZeD.InventoryRenderer
    ZeD.InventoryRenderer = {}
    local keepEvents, keepKeyboard = Events, Keyboard
    Events = { OnKeyPressed = { Add = function(f) handler = f end } }
    Keyboard = { KEY_F6 = 64 }
    isDebugEnabled = function() return dbg end
    getSpecificPlayer = function() asked = asked + 1; return nil end
    assert(loadfile(LUA .. "TestInventory.lua"))()
    check("F6 is bound", handler ~= nil)
    if handler then
        handler(64)
        check("F6 does nothing outside debug", asked == 0, asked)
        dbg = true
        handler(64)
        check("F6 opens the test window in debug", asked == 1, asked)
    end
    ZeD.InventoryRenderer, Events, Keyboard = keepIR, keepEvents, keepKeyboard
end

-- ---------------------------------------------------------------------------
section("the controller map's buttons")
do
    ZeD = ZeD or {}
    local keepWindow = ZeD_Window
    ZeD_Window = {}
    function ZeD_Window:derive(name) local c = { Type = name }; c.__index = c; return setmetatable(c, { __index = self }) end
    local keepJoypad = Joypad
    Joypad = { AButton = 1, BButton = 2 }
    assert(loadfile(LUA .. "ZeD_ControllerMap.lua"))()
    local shut = 0
    local w = setmetatable({ playerNum = 0 }, { __index = ZeD_ControllerMap })
    w.close = function() shut = shut + 1 end
    w:onJoypadDown(Joypad.AButton)
    check("A leaves the map open (the foot offers only B)", shut == 0, shut)
    w:onJoypadDown(Joypad.BButton)
    check("B closes it", shut == 1, shut)
    ZeD_Window, Joypad = keepWindow, keepJoypad
end

require = realRequire
print("code_flags_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
