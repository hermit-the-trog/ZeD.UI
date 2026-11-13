-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/SkillRecoveryJournal.lua
-- ============================================================================
-- SUPPORT FOR SKILL RECOVERY JOURNAL (mod id SkillRecoveryJournal, Workshop
-- 2503622437). Client: the mod's strips, key and numbers on ZeD's Skills tab.
--
-- The mod draws a thin strip under each of the game's skill bars (its
-- "Skill Recovery Journal SkillProgressBar.lua"): grey for the levels the job and
-- traits gave (Starting Level), orange for XP that cannot be written down (TV and
-- tapes: Unrecoverable XP), green for XP recorded in a journal (Recoverable XP),
-- red for XP not yet written (Untranscribed XP). ZeD's Skills tab draws its own
-- rows, so this file puts the same strip under each ZeD row, through the tab's
-- general hook (ZeD.SkillsTab.addExtras):
--   * a strip in its own lane under each row (the row grows by 10 units): the
--     standard framed bar, 8 units tall (ZeD.Atoms.fillBarCompactH), its length as in
--     the mod (how far the skill has come, level / 10), split by the mod's four
--     numbers, the "not yet written" part solid red as the mod draws it; no strip for
--     a skill the mod does not record (its sandbox options) or at 0;
--   * a key block at the top of the tab: the section head, whether a Bound Journal
--     is on the character, who wrote it and where it is, the XP not yet written, and
--     the four words with the library's legend swatches in the mod's colours;
--   * the numbers in the row's hover card (the shared detail card);
--   * a Transcribe key at the right of the journal row, with a Bound Journal on the
--     character: it runs the mod's own Transcribe Into Journal (the function the
--     item's menu entry calls, with the same arguments), under the mod's own word;
--     greyed with the mod's own reason when the menu entry would be.
-- The numbers are the mod's own sums (its SRJ_getProgressAmounts, read through the
-- mod's own functions). ZeD stores nothing and keeps no copy. Pinned skills in the
-- title bar stay text only.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "SkillRecoveryJournal"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/SkillsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.SkillRecoveryJournal = S

-- the mod's own colours (SRJ_GREY, SRJ_ORANGE, SRJ_GREEN, SRJ_RED)
local COL = {
    { r = 0.4, g = 0.4, b = 0.4 },
    { r = 1.0, g = 0.7, b = 0.4 },
    { r = 0.4, g = 1.0, b = 0.4 },
    { r = 1.0, g = 0.4, b = 0.4 },
}
-- the mod's own words for them
local WORDS = { "IGUI_StartingLevelText", "IGUI_DeductedXP", "IGUI_GainedXPText", "IGUI_UntranscribedXP" }
local JOURNAL_TYPE = "Base.SkillRecoveryBoundJournal"

-- the mod's main table (its shared "Skill Recovery Journal Main"), nil if it failed to load
local _srj = nil
local function SRJ()
    if _srj == nil then
        local ok, m = pcall(require, "Skill Recovery Journal Main")
        _srj = (ok and type(m) == "table" and m.modDataHandler and m.ledger) and m or false
    end
    return _srj or nil
end

local function round(n) return math.floor((n or 0) + 0.5) end

-- ---------------------------------------------------------------------------
-- THE MOD'S NUMBERS (its SRJ_getProgressAmounts, step for step), kept half a
-- second per skill: the tab asks every frame
-- ---------------------------------------------------------------------------
local _cache, _cacheWho = {}, nil

--- The mod's four sums for one skill, or nil for a skill it does not record:
--- { totalXP, startingLevel, settledXP, deductedXP, greenXP, deficitXP }.
function S.amounts(char, perk)
    local M = SRJ()
    if not (M and char and perk) then return nil end
    if _cacheWho ~= char then _cache, _cacheWho = {}, char end
    local id = perk:getId()
    local now = getTimestampMs()
    local c = _cache[id]
    if c and now - c.t < 500 then return c.a end
    local a = nil
    local ok = pcall(function()
        local valid = M.bSkillValid(perk)
        if not valid then return end
        local totalXP = char:getXp():getXP(perk)
        local deductedXP = 0
        if SandboxVars.SkillRecoveryJournal.TranscribeTVXP ~= true then
            local d = M.modDataHandler.getDeductedXP(char)
            deductedXP = (d and d[id]) or 0
        end
        local free = M.modDataHandler.getFreeLevelsFromTraitsAndProfession(char)
        local startingLevel = free[id] or 0
        local settledXP = (startingLevel > 0) and perk:getTotalXpForLevel(startingLevel) or 0
        local read = M.ledger.getReadXPAny(char)
        local readXP = (read and read[id]) or 0
        local remaining = math.max(totalXP - settledXP - deductedXP, 0)
        local greenXP = math.min(readXP, remaining)
        a = { totalXP = totalXP, startingLevel = startingLevel, settledXP = settledXP,
              deductedXP = deductedXP, greenXP = greenXP, deficitXP = remaining - greenXP }
    end)
    if not ok then a = nil end
    _cache[id] = { t = now, a = a }
    return a
end

--- The Bound Journal on the character (the first one), who wrote it, and where;
--- nil with none carried.
function S.journal(char)
    local inv = char and char:getInventory()
    if not inv then return nil end
    local item = inv:getFirstTypeRecurse("SkillRecoveryBoundJournal")
    if not item then return nil end
    local where
    local cont = item:getContainer()
    if cont == inv or not (cont and cont:getContainingItem()) then
        where = ZeD.trBare("IGUI_InventoryTooltip")
    else
        where = cont:getContainingItem():getDisplayName()
    end
    local who = nil
    local M = SRJ()
    if M then
        local ok, d = pcall(M.modDataHandler.getDisplayData, item)
        if ok and d and d.author then who = d.author end
    end
    return { item = item, who = who, where = where }
end

-- The journal as the tab shows it, kept a quarter second per character. The key block asks for it
-- several times a frame (its height, the key's, the row, a row's card), and each ask walks every bag
-- the character carries when there is no journal. A press asks S.journal itself, so it never acts on
-- a journal just dropped.
local _shown = { t = -1 }
local function journalShown(char)
    local now = getTimestampMs()
    if _shown.who == char and now >= _shown.t and now - _shown.t < 250 then return _shown.j end
    _shown.who, _shown.t, _shown.j = char, now, S.journal(char)
    return _shown.j
end
S.journalShown = journalShown

local function journalName()
    return getItemNameFromFullType(JOURNAL_TYPE) or JOURNAL_TYPE
end

-- ---------------------------------------------------------------------------
-- TRANSCRIBE (the mod's own: the item menu's Transcribe Into Journal)
-- ---------------------------------------------------------------------------
-- the mod's menu file ("Skill Recovery Journal Context"), nil if it failed to load
local _ctx = nil
local function CTX()
    if _ctx == nil then
        local ok, m = pcall(require, "Skill Recovery Journal Context")
        _ctx = (ok and type(m) == "table" and type(m.writeItems) == "function") and m or false
    end
    return _ctx or nil
end

--- The mod's own reason the menu entry is greyed (its checks, in its order), as text; nil when
--- it can be used. Returns the writing tool too: the menu hands it to the action.
function S.transcribeWhy(char, item)
    local sv = SandboxVars and SandboxVars.SkillRecoveryJournal or {}
    local tool = char:getInventory():getFirstTagRecurse(ItemTag.WRITE)
    local mismatch = false
    local srj = item:getModData()["SRJ"]
    local display = srj and srj.display
    if display and display.author and char.getSteamID and char:getSteamID() ~= 0 then
        local id = display.identity or {}
        if id["steamID"] and id["steamID"] ~= char:getSteamID() then mismatch = true end
    end
    local why
    if char:isAsleep() then why = getText("ContextMenu_NoOptionSleeping")
    elseif char:hasTrait(CharacterTrait.ILLITERATE) and (sv.IlliterateSpeedMultiplier or 0) <= 0 then why = getText("IGUI_PlayerText_Illiterate2")
    elseif mismatch then why = getText("IGUI_PlayerText_DoesntFeelRightToWrite")
    elseif not tool then why = getText("Tooltip_Map_CantWrite")
    elseif char.tooDarkToRead and char:tooDarkToRead() then why = getText("ContextMenu_TooDark")   -- (the action's own check)
    end
    return why, tool
end

-- the answer for the journal row, kept half a second (the tab asks every frame)
local _tr = { t = -1 }
local function transcribeState(char, j)
    local now = getTimestampMs()
    if _tr.who == char and _tr.item == j.item and now - _tr.t < 500 then return _tr end
    local ok, why, tool = pcall(S.transcribeWhy, char, j.item)
    _tr.who, _tr.item, _tr.t = char, j.item, now
    _tr.why, _tr.tool = ok and why or nil, ok and tool or nil
    _tr.ok = ok
    return _tr
end

--- Run the mod's Transcribe Into Journal on the journal: the function its menu entry calls
--- (contextSRJ.writeItems), with the menu's arguments (the items, the player, the writing tool).
--- Returns true when it was called.
function S.transcribe(char, j)
    local C = CTX()
    if not (C and char and j and j.item) then return false end
    local why, tool = S.transcribeWhy(char, j.item)
    if why then
        if HaloTextHelper then HaloTextHelper.addBadText(char, why) end
        return false
    end
    C.writeItems({ j.item }, char, tool)
    return true
end

-- XP not yet written, all recorded skills together (what the red parts add up to)
local _total = { t = -1 }
local function notWrittenTotal(char)
    local now = getTimestampMs()
    if _total.who == char and now - _total.t < 500 then return _total.n end
    local n = 0
    for i = 0, PerkFactory.PerkList:size() - 1 do
        local perk = PerkFactory.PerkList:get(i)
        if perk:getParent() ~= Perks.None and char:getPerkLevel(perk:getType()) > 0 then
            local a = S.amounts(char, perk)
            if a then n = n + a.deficitXP end
        end
    end
    _total.who, _total.t, _total.n = char, now, n
    return n
end

-- ---------------------------------------------------------------------------
-- THE ROW EXTRA
-- ---------------------------------------------------------------------------
local X = { laneH = 10 }

--- The strip under a row: as long as the skill has come (level and a bit, of ten),
--- split by XP. The Skills tab calls it per row.
function X.lane(char, perk, level, progress)
    if not level or level <= 0 then return nil end
    local a = S.amounts(char, perk)
    if not a or a.totalXP <= 0 then return nil end
    local span = (level >= 10) and 1 or math.min(1, (level + (progress or 0)) / 10)
    local t = a.totalXP
    local segs = {}
    local parts = { a.settledXP, a.deductedXP, a.greenXP, a.deficitXP }
    for i = 1, 4 do
        if parts[i] > 0 then segs[#segs + 1] = { share = parts[i] / t, color = COL[i] } end
    end
    if #segs == 0 then return nil end
    return { span = span, segs = segs }
end

-- the key block: the section head, then short rows and a gap
local function lineH()
    local T = ZeD.T
    return math.max(ZeD.TM:getFontHeight(T.fontF1), T.px(ZeD.Atoms.SWATCH_H)) + T.px(4)
end

-- the four words with their swatches, laid in rows that fit w: { { x, word, i }, ... } per row
local function wordRows(w)
    local T, tm = ZeD.T, ZeD.TM
    local rows, row, cx = {}, {}, 0
    for i = 1, 4 do
        local word = ZeD.tr(WORDS[i])
        local need = T.px(ZeD.Atoms.SWATCH_W) + T.px(6) + tm:MeasureStringX(T.fontF1, word)
        if cx > 0 and cx + need > w then rows[#rows + 1] = row; row, cx = {}, 0 end
        row[#row + 1] = { x = cx, word = word, i = i }
        cx = cx + need + T.px(12)
    end
    rows[#rows + 1] = row
    return rows
end

--- How tall the key block is at width w (the Skills tab reserves the space).
function X.headHeight(win, w)
    return ZeD.T.px(20) + X.journalRowH(win) + lineH() * #wordRows(w) + ZeD.T.px(10)
end

-- The Transcribe key's height; it shows with a Bound Journal on the character and the mod's menu loaded
local function keyH() return ZeD.T.buttonH - ZeD.T.px(4) end

-- the journal row's height for the journal shown (j, or nil for none)
local function rowHFor(j)
    local lh = lineH()
    if j and CTX() then return math.max(lh, keyH() + ZeD.T.px(2)) end
    return lh
end

--- The journal row's height: a text line, or the key's height (and a little air) when the key shows.
function X.journalRowH(win)
    local char = win and win._playerObj
    return rowHFor(char and journalShown(char) or nil)
end

-- the pressed key's action (made once; the tab hands it the window)
local function pressTranscribe(win)
    local char = win and win._playerObj
    local j = char and S.journal(char)
    if j then S.transcribe(char, j) end
end

--- The Transcribe key at the right end of the journal row (a stop for the mouse and the
--- controller): ZeD's button, greyed with the mod's own reason when its menu entry would be.
--- Returns the key's left edge.
function X.drawTranscribe(panel, win, char, j, x, y, w, rowH)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local label = ZeD.tr("IGUI_TranscribeIntoJournal")
    local bw, bh = M.buttonW(label), keyH()
    local bx, by = x + w - bw, y + math.floor((rowH - bh) / 2)
    local st = transcribeState(char, j)
    local why = st.why
    local focus = ZeD.SkillsTab.stampStop(win, "srj-transcribe", bx, by, bw, bh, pressTranscribe)
    local hover = A.mouseIn(panel, bx, by, bw, bh, win._skillsHoverView)
    M.drawButton(panel, bx, by, bw, bh, label, "default", hover and isMouseButtonDown(0), nil,
        { hover = hover, disabled = why ~= nil, focus = focus, win = win,
          help = why and ZeD.tr("UI_ZeD_Map_HelpCant", ZeD.btnCase(label), why) or nil })
    return bx
end

--- The key block at the top of the Skills tab: journal row, then the four words.
function X.drawHead(panel, win, x, y, w)
    local T, tm, A, M = ZeD.T, ZeD.TM, ZeD.Atoms, ZeD.Molecules
    local char = win._playerObj
    local f1 = T.fontF1
    local lh = lineH()
    local ts, tx = T.textSec, T.text
    -- the section head: the mod's name, and at the right what is not yet written
    local hh = M.drawSectionHeader(panel, x, y, w, ZeD.tr("IGUI_CraftCategory_SkillJournal"), nil, true, false, nil, nil, nil, nil, true)
    local nw = notWrittenTotal(char)
    if nw > 0 then
        A.drawTextRight(panel, ZeD.tr("UI_ZeD_SRJ_NotWrittenTotal", round(nw)), x + w - T.px(6), y + math.floor((hh - tm:getFontHeight(f1)) / 2), f1, ts)
    end
    y = y + hh
    -- row 1: the journal on the character, or none (a status square, as everywhere)
    local j = journalShown(char)
    local r1 = rowHFor(j)
    local dot = T.px(6)
    local dy = y + math.floor((r1 - dot) / 2)
    local cx = x
    if j then
        A.drawStatusDot(panel, cx, dy, T.positive, dot)
    else
        A.drawStatusHollow(panel, cx, dy, T.borderS, dot)
    end
    cx = cx + dot + T.px(6)
    local main, rest
    if j then
        main = ZeD.tr("UI_ZeD_SRJ_JournalOn", journalName())
        rest = (j.who and (" | " .. ZeD.tr("UI_ZeD_SRJ_WrittenBy", j.who)) or "") .. " | " .. ZeD.tr("UI_ZeD_SRJ_JournalIn", j.where)
    else
        main = ZeD.tr("UI_ZeD_SRJ_JournalNone", journalName())
        rest = " | " .. ZeD.tr("UI_ZeD_SRJ_StaysRecorded")
    end
    local ty = y + math.floor((r1 - tm:getFontHeight(f1)) / 2)
    -- the Transcribe key at the right end of the row (the text gives way to it)
    local right = x + w
    if j and CTX() then right = X.drawTranscribe(panel, win, char, j, x, y, w, r1) - T.px(8) end
    panel:drawText(main, cx, ty, tx.r, tx.g, tx.b, tx.a or 1, f1)
    cx = cx + tm:MeasureStringX(f1, main) + T.px(4)
    panel:drawText(A.truncateText(rest, f1, right - cx), cx, ty, ts.r, ts.g, ts.b, ts.a or 1, f1)
    y = y + r1
    -- the next rows: the four words with the library's legend swatches, in the mod's colours
    for _, row in ipairs(wordRows(w)) do
        for _, it in ipairs(row) do
            A.drawLegendSwatch(panel, x + it.x, y + math.floor((lh - T.px(A.SWATCH_H)) / 2), COL[it.i])
            panel:drawText(it.word, x + it.x + T.px(A.SWATCH_W) + T.px(6), y + math.floor((lh - tm:getFontHeight(f1)) / 2), ts.r, ts.g, ts.b, ts.a or 1, f1)
        end
        y = y + lh
    end
    y = y + T.px(4)
    A.drawDividerH(panel, x, y, w)
end

--- The hover card's lines: Starting Level (and its level), the XP the mod
--- counts, Total XP, and what to do about the red part.
function X.card(char, perk, skill)
    if not skill or skill.level <= 0 then return nil end
    local a = S.amounts(char, perk)
    if not a then return nil end
    local lines = {
        { color = COL[1], text = ZeD.tr(WORDS[1]) .. " (" .. tostring(a.startingLevel) .. ")", value = tostring(round(a.settledXP)) },
    }
    if a.deductedXP > 0 then lines[#lines + 1] = { color = COL[2], text = ZeD.tr(WORDS[2]), value = tostring(round(a.deductedXP)) } end
    if a.greenXP > 0 then lines[#lines + 1] = { color = COL[3], text = ZeD.tr(WORDS[3]), value = tostring(round(a.greenXP)) } end
    if a.deficitXP > 0 then lines[#lines + 1] = { color = COL[4], text = ZeD.tr(WORDS[4]), value = tostring(round(a.deficitXP)) } end
    lines[#lines + 1] = { total = true, text = ZeD.tr("IGUI_Total") .. " " .. ZeD.tr("IGUI_XP_xp"), value = tostring(round(a.totalXP)) }
    local note
    if a.deficitXP > 0 then
        if journalShown(char) then note = ZeD.tr("UI_ZeD_SRJ_NoteOn", round(a.deficitXP))
        else note = ZeD.tr("UI_ZeD_SRJ_NoteNone", round(a.deficitXP)) end
    else
        note = ZeD.tr("UI_ZeD_SRJ_NoteAll")
    end
    return { label = ZeD.tr("IGUI_CraftCategory_SkillJournal"), lines = lines, note = note }
end

S.X = X   -- (the QA scripts drive it)
ZeD.SkillsTab.addExtras(MOD_ID, X)
