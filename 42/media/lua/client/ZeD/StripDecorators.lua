-- ZeD-UI/42/media/lua/client/ZeD/StripDecorators.lua
-- ============================================================================
-- STRIP DECORATORS (a general hook for other mods)
--
-- A mod that marks the game's container buttons (a fill bar, a badge, a tint)
-- gets the same mark on ZeD's container strips by registering a decorator
-- through the window:
--     ZeD_CharacterWindow.addStripDecorator(id, fn)
--     ZeD_WorldWindow.addStripDecorator(id, fn)
-- Each frame, right after a strip button's icon is drawn (before its column
-- number badge, so the badge stays on top), the window calls every decorator
-- of its side:
--     fn(panel, entry, x, y, w, h, win)
--   panel  the strip panel to draw on (draw with its drawRect, the ZeD atoms ...)
--   entry  the window's own entry for that button: entry.inventory is the
--          ItemContainer, entry.name / entry.texture / entry.item as listed
--          (the World window's entries also carry isFloor, locked, sourceType)
--   x, y, w, h  the button's rectangle in the panel's own coordinates, inside
--          the strip's edge line and above the line under the button
--   win    the window
-- A decorator draws inside that rectangle only and keeps its own state out of
-- the entry. One that throws an error is skipped for that call (the strip
-- never breaks on another mod); the first error per id is kept in
-- ZeD.StripDecorators.errors[id] for QA and logs. A second add with the same
-- id replaces the first. A button scrolled out of the strip is clipped by the
-- strip, so a decorator may be called for one that is not in view.
--
-- QA: every decorator that ran without error is stamped on the window,
-- win._stripDecorated[ItemContainer][id] = true.
-- ============================================================================

ZeD = ZeD or {}
-- One registry per window side. `or` keeps the registries if this file is
-- loaded a second time (a debug reload), so decorators already added stay.
local X = ZeD.StripDecorators or { char = {}, world = {}, errors = {} }
ZeD.StripDecorators = X

-- Adds (or replaces, by id) a decorator for one side: "char" or "world".
function X.add(side, id, fn)
    local reg = X[side]
    if not reg or type(fn) ~= "function" then return end
    for _, d in ipairs(reg) do
        if d.id == id then d.fn = fn; return end   -- same id: the newer function wins
    end
    reg[#reg + 1] = { id = id, fn = fn }
end

-- Calls every decorator of `side` for one button. Called by the two strips
-- every frame, so with nothing registered it returns at once.
function X.run(panel, win, side, entry, x, y, w, h)
    local reg = X[side]
    if not reg or #reg == 0 or not entry then return end
    local inv = entry.inventory
    for _, d in ipairs(reg) do
        -- pcall: an error in the decorator (another mod's code) only skips it
        local ok, err = pcall(d.fn, panel, entry, x, y, w, h, win)
        if ok then
            if inv then
                -- the stamp QA reads (Java objects work as table keys)
                local st = win._stripDecorated
                if not st then st = {}; win._stripDecorated = st end
                local per = st[inv]
                if not per then per = {}; st[inv] = per end
                per[d.id] = true
            end
        elseif X.errors[d.id] == nil then
            X.errors[d.id] = tostring(err)    -- kept once, never printed per frame
        end
    end
end
