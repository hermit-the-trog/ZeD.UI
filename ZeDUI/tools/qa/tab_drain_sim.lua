-- ZeDUI/tools/qa/tab_drain_sim.lua  (Nov 7 2026, Build): the clips a tab leaves on, with no game running (punch list 95 and 97).
-- Both windows' drawers clear, after the tab draws, whatever clips the tab left on, counting the ones an item card's cover adds
-- (coverClear sets the card's cut again after every clear). This sim cuts the real pieces out of ZeD_CharacterWindow.lua,
-- ZeD_WorldWindow.lua and ZeD_Panel.lua (the cover helpers, the drawer's tab block with its drain, ZeD_Panel's counting
-- set/clear) and runs them over a model of the game's stencil level (zombie.ui.UIElement.stencilLevel: a set adds one, a clear
-- takes one off and does nothing at 0, javap -c on the 42.22.2 jar). Fake tabs draw 0 to 3 set/clear pairs, an unbalanced set,
-- the CookingTab column relay, the old nested detail clip and a throw, with and without a card. Each must leave the game's level
-- where it was before the tab drew. A last check takes the drain out and shows the sim catches it.
-- What it can't show is how it looks: Journal > Recipes under an item card, in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/tab_drain_sim.lua
-- It prints FAIL lines and a last line "tab_drain_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]tab_drain_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(rel)
    local f = assert(io.open(ROOT .. rel, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end

-- The text from the first `from` (searched from `init`) to the end of the line where the first `to` after it ends
-- (plain finds, no patterns). Nil when either is missing, so a renamed line shows up as a FAIL, not a crash.
local function cut(src, from, to, init)
    local a = string.find(src, from, init or 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src   -- (the line the end of `to` is on)
    return string.sub(src, a, e), e
end

-- ---------------------------------------------------------------------------
-- THE GAME'S STENCIL LEVEL (zombie.ui.UIElement, per frame)
-- ---------------------------------------------------------------------------
local J = { level = 0 }
local ISPanel = {}
function ISPanel.setStencilRect(_, _, _, _, _) J.level = J.level + 1 end
function ISPanel.clearStencilRect(_) if J.level > 0 then J.level = J.level - 1 end end

-- ZeD_Panel's own counting set/clear, from its source
local ZeD_Panel = {}
do
    local src = readFile("42/media/lua/client/ZeD/ZeD_Panel.lua")
    local s = cut(src, "function ZeD_Panel:setStencilRect(", "\nend")
    local c = cut(src, "function ZeD_Panel:clearStencilRect(", "\nend")
    check("ZeD_Panel's set and clear are found", s ~= nil and c ~= nil)
    local chunk = assert(loadstring("local ZeD_Panel, ISPanel = ...\n" .. (s or "") .. (c or "")))
    chunk(ZeD_Panel, ISPanel)
end
ZeD_Panel.__index = ZeD_Panel

-- (the drawer's error fallback logs once; the sim only notes it)
local logged = 0
local ZeD = { logOnce = function() logged = logged + 1 end }

-- A window's cover helpers and the drawer's tab block (from "local clipsBefore" to the error fallback's end),
-- built into a function the sim can call. With noDrain, the drain line is taken out (the check that the sim has teeth).
local function loadWindow(rel, name, noDrain)
    local src = readFile(rel)
    -- (coverStencil to setTabCover's end: the three helpers sit in a row)
    local helpers
    local a = string.find(src, "local function coverStencil(", 1, true)
    local tabAt = a and string.find(src, "local function setTabCover(", a, true)
    if tabAt then
        local _, e = cut(src, "local function setTabCover(", "\nend", tabAt)
        if e then helpers = string.sub(src, a, e) end
    end
    local block, blockEnd = cut(src, "local clipsBefore = self._zedStencilN", "ZeD.logOnce(")
    if block then
        -- (and the fallback's closing "end", the line after logOnce)
        local e2 = string.find(src, "\n", blockEnd + 1, true)
        block = block .. string.sub(src, blockEnd + 1, e2)
    end
    local drainLine = "for _ = 1, (self._zedStencilN or 0) - clipsBefore + self._coverClears do self:clearStencilRect() end"
    check(name .. ": cover helpers found", helpers ~= nil)
    check(name .. ": drawer tab block found", block ~= nil)
    check(name .. ": drain is in the block", block ~= nil and string.find(block, "self._coverClears", 1, true) ~= nil)
    if not (helpers and block) then return nil end
    if noDrain then
        local a, b = string.find(block, drainLine, 1, true)
        if not a then return nil end
        block = string.sub(block, 1, a - 1) .. string.sub(block, b + 1)
    end
    local hchunk = assert(loadstring("local ZeD_Panel, ISPanel = ...\n" .. helpers
        .. "\nreturn coverStencil, coverClear, setTabCover", "=" .. name .. " helpers"))
    local _, _, setTabCover = hchunk(ZeD_Panel, ISPanel)
    -- (the block reads coverX in the Character window and coverL in the World window; both are passed in)
    local bchunk = assert(loadstring("local setTabCover, ZeD = ...\n"
        .. "return function(self, win, renderer, targetW, effectiveW, dh, coverX, coverL)\n" .. block .. "\nreturn okR\nend",
        "=" .. name .. " drawer"))
    return { setTabCover = setTabCover, run = bchunk(setTabCover, ZeD) }
end

-- ---------------------------------------------------------------------------
-- FAKE TABS (each draws on the drawer as a tab renderer does)
-- ---------------------------------------------------------------------------
local function pairsOf(k)
    return function(self)
        for _ = 1, k do
            self:setStencilRect(4, 4, 100, 50)
            self:clearStencilRect()
        end
    end
end
local TABS = {
    { "no clips", pairsOf(0) },
    { "one pair", pairsOf(1) },
    { "two pairs (Journal > Recipes with a recipe picked)", pairsOf(2) },
    { "three pairs (and the category dropdown)", pairsOf(3) },
    -- the old Admin, Server and ticket card ending: list clip, clear, the whole panel again, never cleared
    { "one left on", function(self)
        self:setStencilRect(4, 4, 100, 50); self:clearStencilRect(); self:setStencilRect(0, 0, 200, 100)
    end },
    { "two pairs and one left on", function(self)
        pairsOf(2)(self); self:setStencilRect(0, 0, 200, 100)
    end },
    -- CookingTab's relayClip: a clip, then per column a clear and a set, then the last clear
    { "the column relay", function(self)
        self:setStencilRect(0, 0, 60, 100)
        for col = 1, 3 do self:clearStencilRect(); self:setStencilRect(col * 60, 0, 60, 100) end
        self:clearStencilRect()
    end },
    -- the old mod-support detail: a second clip inside the first, one clear
    { "nested clip, one clear", function(self)
        self:setStencilRect(0, 0, 200, 100); self:setStencilRect(0, 0, 180, 100); self:clearStencilRect()
    end },
    { "a tab that throws with its clip set", function(self)
        self:setStencilRect(4, 4, 100, 50); error("sim: the tab broke")
    end },
}

-- One frame of the drawer: its own clip, the card's cut when a card is open (as each window sets it up), the
-- tab block, then the drawer's last clear. base = the clips the window already has on (the drawer's parents).
local function frame(win, which, tab, card, base)
    J.level = base
    local p = setmetatable({ _zedStencilN = 0 }, ZeD_Panel)
    p.getWidth = function() return 400 end
    p.getHeight = function() return 300 end
    local effectiveW, dh, targetW = 400, 300, 400
    p:setStencilRect(0, 0, effectiveW, dh)
    local coverX, coverL
    if card then
        if which == "char" then
            -- (the card on the right: the tab draws left of coverX)
            coverX = 250
            p:clearStencilRect(); p:setStencilRect(0, 0, coverX, dh); win.setTabCover(p, coverX)
        else
            -- (the card on the left: the tab draws right of coverL)
            coverL = 150
            p:clearStencilRect(); p:setStencilRect(coverL, 0, effectiveW - coverL, dh); win.setTabCover(p, coverL, effectiveW)
        end
    end
    local before = J.level
    win.run(p, {}, tab, targetW, effectiveW, dh, coverX, coverL)
    local after = J.level
    p:clearStencilRect()
    return before, after, J.level, p
end

for _, w in ipairs({
    { "char", "Character window", "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua" },
    { "world", "World window", "42/media/lua/client/ZeD/ZeD_WorldWindow.lua" },
}) do
    local which, name, rel = w[1], w[2], w[3]
    section(name)
    local win = loadWindow(rel, name)
    if win then
        for _, t in ipairs(TABS) do
            for _, card in ipairs({ false, true }) do
                for base = 0, 1 do
                    local label = name .. ", " .. t[1] .. (card and ", under a card" or "") .. ", " .. base .. " on before"
                    local before, after, final, p = frame(win, which, t[2], card, base)
                    check(label .. ": the tab ends where it began", after == before, "before " .. before .. ", after " .. after)
                    check(label .. ": the drawer ends where it began", final == base, "end " .. final)
                    check(label .. ": the card's helpers are off again", rawget(p, "setStencilRect") == nil and rawget(p, "clearStencilRect") == nil)
                    check(label .. ": ZeD's count is not below 0", (p._zedStencilN or 0) >= 0)
                end
            end
        end
        -- many frames in a row on one panel: the count ZeD keeps doesn't climb (it carries across frames; the game's level doesn't)
        local p = setmetatable({ _zedStencilN = 0 }, ZeD_Panel)
        p.getWidth = function() return 400 end
        p.getHeight = function() return 300 end
        local n0
        for i = 1, 10 do
            J.level = 0
            p:setStencilRect(0, 0, 400, 300)
            if which == "char" then
                p:clearStencilRect(); p:setStencilRect(0, 0, 250, 300); win.setTabCover(p, 250)
                win.run(p, {}, pairsOf(2), 400, 400, 300, 250, nil)
            else
                p:clearStencilRect(); p:setStencilRect(150, 0, 250, 300); win.setTabCover(p, 150, 400)
                win.run(p, {}, pairsOf(2), 400, 400, 300, nil, 150)
            end
            p:clearStencilRect()
            if i == 1 then n0 = p._zedStencilN end
        end
        check(name .. ": ZeD's count stays put over ten frames under a card", p._zedStencilN == n0 and n0 == 0, p._zedStencilN)
        check(name .. ": the throwing tab was logged", logged > 0)
        logged = 0

        -- teeth: without the drain, two pairs under a card leave the game's level two up (Journal > Recipes lost its list)
        local bare = loadWindow(rel, name .. " (drain taken out)", true)
        check(name .. ": the drain line can be taken out", bare ~= nil)
        if bare then
            local before, after = frame(bare, which, pairsOf(2), true, 0)
            check(name .. ": without the drain, two pairs under a card are caught", after == before + 2, "before " .. before .. ", after " .. after)
        end
    end
end

print("tab_drain_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
