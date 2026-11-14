-- ZeD-UI/42/media/lua/client/ZeD/PlayerTheme.lua
-- ============================================================================
-- PER-PLAYER THEME (split view; the director, Nov 13 2026)
-- In split view each local player picks their own base theme (Dark, Light, High Contrast), status set and accent,
-- saved with their character; the text size and UI scale stay one for the whole screen. The first player's theme is
-- the shared ZeD.T, set from ZeD setup as before; players 2 to 4 with no choice of their own follow it.
--
--   ZeD.Theme.choice[pn]            { base, accent, status } for players 1 to 3 (nil: follow the first player)
--   ZeD.Theme.set(pn, base, accent, status)   a player's pick (nil keeps that part), saved on the character
--   ZeD.Theme.keysFor(pn)           base, accent, status the player draws in (the menus' check marks)
--   ZeD.Theme.adopt(el, pn)         el and everything it draws inside draw in pn's table (ZeD.Tfor, Tokens.lua)
--   ZeD.Theme.ownerPn(el)           the player an element belongs to (its playerNum or player, or a parent's)
--
-- How adopt works: every panel reads ZeD.T fresh each frame, so the switch is one assignment. The element's
-- prerender sets ZeD.T to its player's table, its children draw inside it, and its render puts the shared table
-- back. The switch is the outermost layer of the element's own draw, so a window's own accent and see-through
-- (Organisms.lua _drawFrame / _restoreAccent) happen inside it, on the player's table. For the first player, with
-- split view off, or a player who follows the first player, the table is the shared one and the wrapper costs a
-- compare. OnPreUIDraw puts the shared table back each frame in case a draw failed half way.
-- ============================================================================

ZeD = ZeD or {}
ZeD.Theme = ZeD.Theme or {}
local TH = ZeD.Theme
TH.choice = TH.choice or {}

-- ---------------------------------------------------------------------------
-- WHOSE ELEMENT
-- ---------------------------------------------------------------------------
local function numOf(e)
    local pn = e.playerNum
    if type(pn) == "number" then return pn end
    pn = e.player
    if type(pn) == "number" then return pn end
    return nil
end

--- The player an element belongs to: its own playerNum (or player), else its parents' (a list row inside a window).
--- 0 when nothing says.
function TH.ownerPn(el)
    local e = el
    for _ = 1, 12 do
        if type(e) ~= "table" then return 0 end
        local pn = numOf(e)
        if pn then return pn end
        e = e.parent
    end
    return 0
end

-- the player an adopted element draws for this frame: the number or function it was adopted with, else its own
local function pnOf(self)
    local pn = self._themePn
    if type(pn) == "function" then
        local ok, v = pcall(pn, self)
        pn = ok and v or 0
    elseif pn == nil then
        pn = numOf(self)
    end
    if type(pn) ~= "number" then return 0 end
    return pn
end

-- ---------------------------------------------------------------------------
-- THE CHOICE
-- ---------------------------------------------------------------------------
-- (players 2 to 4 only: the first player's theme lives in ZeD setup's options, as before)
local function validPn(pn) return type(pn) == "number" and pn >= 1 and pn <= 3 end

--- The base, accent and status set player pn draws in (the shared ones for the first player and outside split view)
function TH.keysFor(pn)
    local T = ZeD.Tfor and ZeD.Tfor(pn) or ZeD.T
    if T and T.baseKey then return T.baseKey, T.accentKey, T.statusKey end
    return ZeD.currentBase, ZeD.currentAccent, ZeD.currentStatus
end

--- Write player pn's choice onto their character (ZeD_Theme in the character's mod data; `own` marks it as their
--- own pick, so a character that was the first player once, whose copy of the first player's theme is there too, is
--- not read back as a choice).
function TH.save(pn)
    if not validPn(pn) or not getSpecificPlayer then return end
    local p = getSpecificPlayer(pn)
    if not p then return end
    local c = TH.choice[pn]
    local md = p:getModData()
    if not c then
        if md.ZeD_Theme then md.ZeD_Theme.own = nil end
        return
    end
    md.ZeD_Theme = md.ZeD_Theme or {}
    local t = md.ZeD_Theme
    t.base, t.accent, t.status, t.own = c.base, c.accent, c.status, true
end

--- Player pn's own pick: nil keeps that part of their choice (or the first player's, for a first pick).
--- A new choice table each time, so ZeD.Tfor builds the player's table again (it keeps by the table).
function TH.set(pn, base, accent, status)
    if not validPn(pn) then return end
    local old = TH.choice[pn]
    local b0, a0, s0 = TH.keysFor(pn)
    local c = {
        base   = base   or (old and old.base)   or b0,
        accent = accent or (old and old.accent) or a0,
        status = status or (old and old.status) or s0,
    }
    TH.choice[pn] = c
    if ZeD._playerT then ZeD._playerT[pn] = nil end
    -- the windows' own accent palettes are kept by base, accent, status and alpha: nothing to clear there
    TH.save(pn)
end

--- Back to following the first player
function TH.clear(pn)
    if not validPn(pn) then return end
    TH.choice[pn] = nil
    if ZeD._playerT then ZeD._playerT[pn] = nil end
    TH.save(pn)
end

-- A player's own choice comes back with their character (a new character, a respawn, a player joining): no own
-- choice there means they follow the first player
local function onCreatePlayer(pn, player)
    if not validPn(pn) then return end
    TH.choice[pn] = nil
    if ZeD._playerT then ZeD._playerT[pn] = nil end
    local md = player and player.getModData and player:getModData()
    local t = md and md.ZeD_Theme
    if type(t) == "table" and t.own then
        TH.choice[pn] = { base = t.base, accent = t.accent, status = t.status }
    end
end

-- ---------------------------------------------------------------------------
-- ADOPT
-- ---------------------------------------------------------------------------
local function classFn(self, name)
    local mt = getmetatable(self)
    return mt and mt[name]
end

-- (a later wrapper put over ours, e.g. a window's own render added after it opened: ours goes back on top, a few
-- times at most, so two wrappers that each insist on the top never grow the chain without end)
local READOPT_MAX = 4

--- el (a panel, window or layer) and what it draws inside draw in player pn's table.
--- pn: a number, a function(el) returning one (an element that serves more than one player), or nil to read
--- el.playerNum / el.player each frame. An element fixed to the first player is left alone (it draws as today),
--- unless `always`: an element whose player is set after it goes up (the Character and World windows set
--- playerNum after addToUIManager), which then pays the wrapper's compare each frame.
function TH.adopt(el, pn, always)
    if type(el) ~= "table" then return el end
    if always then
        -- (no early way out: the player is read each frame)
    elseif pn == nil then
        local own = numOf(el)
        if own == nil or own == 0 then return el end
    elseif type(pn) == "number" and pn == 0 then
        return el
    end
    el._themePn = pn
    -- (adopted again, a menu opened again: ours is still on top, so only the player is new)
    if el._themePre and rawget(el, "prerender") == el._themePre and rawget(el, "render") == el._themeRen then return el end
    local basePre, baseRen = rawget(el, "prerender"), rawget(el, "render")
    local pre, ren
    pre = function(self)
        local f = basePre or classFn(self, "prerender")
        -- an older layer of ours under a newer one, or split view off: the draw as it was
        if self._themePre ~= pre or ZeD.splitWindows ~= true then
            if f then return f(self) end
            return
        end
        if (rawget(self, "prerender") ~= pre or rawget(self, "render") ~= ren) and (self._themeReadopt or 0) < READOPT_MAX then
            self._themeReadopt = (self._themeReadopt or 0) + 1
            TH.adopt(self, self._themePn, true)
            return self._themePre(self)
        end
        local P = ZeD.Tfor(pnOf(self))
        local cur = ZeD.T
        if not P or P == cur then
            self._themeOn = nil
            if f then return f(self) end
            return
        end
        self._themeOn, self._themePrev = true, cur
        ZeD.T = P
        if f then
            local ok, err = pcall(f, self)
            if not ok then
                -- (the render that puts the table back may not run after a failed prerender)
                self._themeOn = nil
                ZeD.T = ZeD._sharedT or cur
                error(err)
            end
        end
    end
    ren = function(self)
        local f = baseRen or classFn(self, "render")
        if self._themeRen ~= ren or not self._themeOn then
            if f then return f(self) end
            return
        end
        local ok, err = true, nil
        if f then ok, err = pcall(f, self) end
        self._themeOn = nil
        -- back to the table that was in use before this element (the shared one at the top level); one from before
        -- a new theme was applied during the draw is gone, so the new shared table then
        local prev = self._themePrev
        self._themePrev = nil
        local S = ZeD._sharedT
        if prev and prev.themeGen ~= nil and prev.themeGen == (S and S.themeGen) then
            ZeD.T = prev
        else
            ZeD.T = S or prev or ZeD.T
        end
        if not ok then error(err) end
    end
    el._themePre, el._themeRen = pre, ren
    el.prerender, el.render = pre, ren
    return el
end

-- ---------------------------------------------------------------------------
-- EVENTS
-- ---------------------------------------------------------------------------
if Events then
    -- each UI frame starts on the shared table (a draw that failed half way left a player's table in place)
    if Events.OnPreUIDraw then
        Events.OnPreUIDraw.Add(function()
            local S = ZeD._sharedT
            if S and ZeD.T ~= S then ZeD.T = S end
        end)
    end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
end
TH._onCreatePlayer = onCreatePlayer
