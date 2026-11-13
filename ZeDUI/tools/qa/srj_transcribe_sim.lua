-- ZeDUI/tools/qa/srj_transcribe_sim.lua  (Nov 11 2026, Build; punch list 172): the Transcribe key in the Skills
-- tab's Skill Recovery Journal key line, with no game running. It loads the real SkillsTab.lua and the real
-- ModSupport/SkillRecoveryJournal.lua over stubs of the game and of the mod, and shows:
--   * the mod off: the support adds nothing (no extra, no key);
--   * the mod on, no Bound Journal on the character: the key block draws, no key, no stop;
--   * a journal on the character: the key draws enabled, is a stop for the mouse and the controller, and a press
--     calls the mod's own writeItems (the function the item menu's Transcribe Into Journal calls) with the menu's
--     arguments (the items, the player, the writing tool);
--   * the mod's own reasons grey it (asleep, illiterate, someone else's journal, no pen, too dark) with its words,
--     and a press then calls nothing;
--   * the journal looked for once per quarter second, not four times a frame (each look walks every bag), and a
--     press still looks at once;
--   * the mod's menu file failing to load: no key.
-- What it can't show is how it looks and the real timed action: the in-game list in the build's QA notes.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/srj_transcribe_sim.lua
-- It prints FAIL lines and a last line "srj_transcribe_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]srj_transcribe_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local ACTIVE = { "SkillRecoveryJournal", "ZeD_UI" }
getActivatedMods = function() return list(ACTIVE) end
local TEXT = {
    IGUI_TranscribeIntoJournal = "Transcribe Into Journal",
    ContextMenu_NoOptionSleeping = "Can't while asleep.",
    IGUI_PlayerText_Illiterate2 = "I am illiterate.",
    IGUI_PlayerText_DoesntFeelRightToWrite = "Doesn't feel right to write in someone else's journal.",
    Tooltip_Map_CantWrite = "You need something to write with.",
    ContextMenu_TooDark = "Too dark to read.",
}
getText = function(k) return TEXT[k] or k end
getTimestampMs = function() return 1000 end
getItemNameFromFullType = function() return "Bound Journal" end
isMouseButtonDown = function() return false end
Perks = { None = "None" }
PerkFactory = { PerkList = list({}) }
CharacterTrait = { ILLITERATE = "ILLITERATE" }
ItemTag = { WRITE = "WRITE" }
SandboxVars = { SkillRecoveryJournal = { IlliterateSpeedMultiplier = 0 } }
local halo = {}
HaloTextHelper = { addBadText = function(_, t) halo[#halo + 1] = t end }

-- the mod's two files, as `require` hands them out
local writeCalls = {}
local CONTEXT_OK = true
local SRJ_MAIN = {
    modDataHandler = { getDisplayData = function() return { author = "Alex Cross" } end,
                       getDeductedXP = function() return {} end,
                       getFreeLevelsFromTraitsAndProfession = function() return {} end },
    ledger = { getReadXPAny = function() return {} end },
    bSkillValid = function() return true end,
}
local SRJ_CONTEXT = { writeItems = function(items, player, tool) writeCalls[#writeCalls + 1] = { items = items, player = player, tool = tool } end }
require = function(name)
    if name == "Skill Recovery Journal Main" then return SRJ_MAIN end
    if name == "Skill Recovery Journal Context" then
        if not CONTEXT_OK then error("not loaded") end
        return SRJ_CONTEXT
    end
    return nil
end

-- ZeD's atoms and molecules: they record what the support asks for
local COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
local buttons = {}
ZeD = {
    T = setmetatable({ px = function(n) return n end, buttonH = 24, sp = { xs = 3 } },
                     { __index = function() return COLOR end }),
    TM = { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end },
    tr = function(k, a)
        if k == "UI_ZeD_Map_HelpCant" then return "HELP" end
        return TEXT[k] or k
    end,
    trBare = function(k) return k end,
    btnCase = function(s) return s end,
    textCase = function(s) return s end,
    Safe = { on = function() return false end },
    Atoms = {
        SWATCH_W = 10, SWATCH_H = 8,
        drawStatusDot = noop, drawStatusHollow = noop, drawLegendSwatch = noop, drawDividerH = noop, drawTextRight = noop,
        truncateText = function(_, s) return s end,
        mouseIn = function() return false end,
    },
    Molecules = {
        drawSectionHeader = function() return 20 end,
        buttonW = function(s) return math.max(#s * 7 + 20, 60) end,
        drawButton = function(_, x, y, w, h, text, variant, pressed, colors, opts)
            buttons[#buttons + 1] = { x = x, y = y, w = w, h = h, text = text, opts = opts }
        end,
    },
}
local panel = { drawText = noop, drawRect = noop }

local function journalItem(inv)
    local it = { modData = {} }
    it.getContainer = function() return inv end
    it.getModData = function() return it.modData end
    it.getDisplayName = function() return "Bound Journal" end
    return it
end
-- a character: with or without a journal and a pen, asleep, illiterate, dark
local function char(o)
    local inv = {}
    local item = o.journal and journalItem(inv) or nil
    inv.getFirstTypeRecurse = function() return item end
    inv.getFirstTagRecurse = function() return o.pen and "PEN" or nil end
    local c = {
        getInventory = function() return inv end,
        isAsleep = function() return o.asleep == true end,
        hasTrait = function(_, t) return t == "ILLITERATE" and o.illiterate == true end,
        getSteamID = function() return o.steam or 0 end,
        tooDarkToRead = function() return o.dark == true end,
        getXp = function() return { getXP = function() return 0 end } end,
    }
    c.item = item
    return c
end

local function fresh()
    buttons, writeCalls, halo = {}, {}, {}
    local win = {}
    return win
end
local function drawHeadFor(X, win, c)
    win._playerObj = c
    ZeD.SkillsTab.stampStop(win, "reset", 0, 0, 0, 0, nil)   -- (makes the list exist)
    win._skillsStops.n = 0                                    -- (the tab clears it each frame)
    X.drawHead(panel, win, 0, 0, 400)
end

-- ---------------------------------------------------------------------------
-- THE MOD OFF
-- ---------------------------------------------------------------------------
dofile(ROOT .. "42/media/lua/client/ZeD/SkillsTab.lua")
ACTIVE = { "ZeD_UI" }
dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/SkillRecoveryJournal.lua")
check("mod off: no support loaded", ZeD.ModSupport == nil or ZeD.ModSupport.SkillRecoveryJournal == nil)
check("mod off: no extra added", #ZeD.SkillsTab.extras == 0)

-- ---------------------------------------------------------------------------
-- THE MOD ON
-- ---------------------------------------------------------------------------
ACTIVE = { "SkillRecoveryJournal", "ZeD_UI" }
dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/SkillRecoveryJournal.lua")
local S = ZeD.ModSupport.SkillRecoveryJournal
local X = S.X
check("mod on: the extra is added", S ~= nil and #ZeD.SkillsTab.extras == 1)

-- no journal
local win = fresh()
local noJ = char({ journal = false, pen = true })
local hNo = X.headHeight((function() win._playerObj = noJ; return win end)(), 400)
drawHeadFor(X, win, noJ)
check("no journal: no key drawn", #buttons == 0, #buttons)
check("no journal: no stop", win._skillsStops.n == 0, win._skillsStops.n)
check("no journal: a click does nothing", ZeD.SkillsTab.onClick(win, 390, 10) == false)

-- a journal, a pen
win = fresh()
local c1 = char({ journal = true, pen = true })
win._playerObj = c1
local hYes = X.headHeight(win, 400)
check("journal: the head is taller by the key's room", hYes > hNo, hYes .. " vs " .. hNo)
drawHeadFor(X, win, c1)
check("journal: the key is drawn", #buttons == 1, #buttons)
local b = buttons[1] or {}
check("journal: in the mod's own word", b.text == "Transcribe Into Journal", b.text)
check("journal: enabled", b.opts and b.opts.disabled == false)
check("journal: one stop, in the key's place", win._skillsStops.n == 1 and win._skillsStops[1].id == "srj-transcribe"
    and win._skillsStops[1].x == b.x and win._skillsStops[1].w == b.w and win._skillsStops[1].y == b.y)
check("journal: the key at the right end of the row", b.x + b.w == 400, b.x + b.w)
-- a press (the mouse's route and the controller's: the same onPress)
local took = ZeD.SkillsTab.onClick(win, b.x + 2, b.y + 2)
check("press: the tab took it", took == true)
check("press: the mod's writeItems called once", #writeCalls == 1, #writeCalls)
local wc = writeCalls[1] or {}
check("press: with the journal item, the player and the pen (the menu's arguments)",
    wc.items and #wc.items == 1 and wc.items[1] == c1.item and wc.player == c1 and wc.tool == "PEN")
writeCalls = {}
win._skillsStops[1].onPress(win)
check("controller A: the same call", #writeCalls == 1)
check("a press off the key is not taken", ZeD.SkillsTab.onClick(win, 5, 5) == false and #writeCalls == 1)

-- the mod's own reasons
local function greyed(name, o, why)
    local w = fresh()
    local c = char(o)
    -- (the answer is kept half a second: step the clock)
    getTimestampMs = (function(t) return function() t = t + 1000; return t end end)(getTimestampMs())
    drawHeadFor(X, w, c)
    local bt = buttons[1]
    check(name .. ": key still shown", bt ~= nil)
    check(name .. ": greyed", bt and bt.opts.disabled == true)
    check(name .. ": help is the reason", bt and bt.opts.help == "HELP")
    ZeD.SkillsTab.onClick(w, bt.x + 2, bt.y + 2)
    check(name .. ": a press calls nothing", #writeCalls == 0)
    check(name .. ": a press says the mod's reason", halo[1] == why, halo[1])
    -- the reason itself, as the mod words it
    local got = S.transcribeWhy(c, c.item)
    check(name .. ": the mod's words", got == why, got)
end
greyed("no pen", { journal = true, pen = false }, TEXT.Tooltip_Map_CantWrite)
greyed("asleep", { journal = true, pen = true, asleep = true }, TEXT.ContextMenu_NoOptionSleeping)
greyed("illiterate", { journal = true, pen = true, illiterate = true }, TEXT.IGUI_PlayerText_Illiterate2)
greyed("too dark", { journal = true, pen = true, dark = true }, TEXT.ContextMenu_TooDark)
-- someone else's journal
do
    local c = char({ journal = true, pen = true, steam = 111 })
    c.item.modData.SRJ = { display = { author = "Other", identity = { steamID = 222 } } }
    check("someone else's journal: the mod's reason", S.transcribeWhy(c, c.item) == TEXT.IGUI_PlayerText_DoesntFeelRightToWrite)
    local c2 = char({ journal = true, pen = true, steam = 222 })
    c2.item.modData.SRJ = { display = { author = "Other", identity = { steamID = 222 } } }
    check("your own written journal: allowed", S.transcribeWhy(c2, c2.item) == nil)
    local c3 = char({ journal = true, pen = true, illiterate = true })
    SandboxVars.SkillRecoveryJournal.IlliterateSpeedMultiplier = 0.5
    check("illiterate with the sandbox option allowing it: allowed", S.transcribeWhy(c3, c3.item) == nil)
    SandboxVars.SkillRecoveryJournal.IlliterateSpeedMultiplier = 0
end

-- The journal is looked for once a quarter second at most, not four times a frame (Nov 12 2026 review): the key
-- block's height (the tab measures it), the key's height, the row and its height each walked every bag the character
-- carries. A press still looks at once, so a journal just dropped is never written into.
do
    local t = 50000
    getTimestampMs = function() return t end
    local w = fresh()
    local c = char({ journal = false, pen = true })
    local inv = c.getInventory()
    local walk, walks = inv.getFirstTypeRecurse, 0
    inv.getFirstTypeRecurse = function(...) walks = walks + 1; return walk(...) end
    w._playerObj = c
    X.headHeight(w, 400)        -- (the tab's measure)
    drawHeadFor(X, w, c)        -- (the block drawn)
    check("one frame of the key block: the bags walked for the journal once", walks == 1, walks)
    t = t + 16
    X.headHeight(w, 400)
    drawHeadFor(X, w, c)
    check("the next frame: not walked again", walks == 1, walks)
    t = t + 300
    X.headHeight(w, 400)
    check("a quarter second on: walked again (a journal picked up shows)", walks == 2, walks)
    -- a journal on the character, the key drawn; then taken off: a press right after writes nothing
    local c2 = char({ journal = true, pen = true })
    local w2 = fresh()
    drawHeadFor(X, w2, c2)
    local key = buttons[1]
    c2.getInventory().getFirstTypeRecurse = function() return nil end
    writeCalls = {}
    if key then ZeD.SkillsTab.onClick(w2, key.x + 2, key.y + 2) end
    check("a press right after the journal was taken off writes nothing (the press looks again)", key ~= nil and #writeCalls == 0)
    getTimestampMs = function() return 1000 end
end

-- the mod's menu file missing: no key (and no gap)
do
    CONTEXT_OK = false
    -- (a fresh load of the support: the module caches the mod's table)
    ACTIVE = { "SkillRecoveryJournal", "ZeD_UI" }
    dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/SkillRecoveryJournal.lua")
    local X2 = ZeD.ModSupport.SkillRecoveryJournal.X
    local w = fresh()
    drawHeadFor(X2, w, char({ journal = true, pen = true }))
    check("the mod's menu failed to load: no key", #buttons == 0 and w._skillsStops.n == 0)
    check("the mod's menu failed to load: head as without a journal", X2.headHeight(w, 400) == hNo)
    CONTEXT_OK = true
end

print(string.format("srj_transcribe_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
