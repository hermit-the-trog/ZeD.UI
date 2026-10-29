-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/TraitsTab.lua
-- ============================================================================
-- THE TRAITS TAB'S SOURCES (shared by the support files of mods that add trait progress)
--
-- ZeD's Character window has one Traits tab, right after Skills. Whichever support file
-- owns it draws its own rows first (Traits As Skills, ModSupport/traitsAsSkills.lua);
-- the support of any other mod (Evolving Traits World, ModSupport/EvolvingTraitsWorld.lua)
-- adds its rows here as a source, and the tab draws them as their own section(s) in the
-- same scroll, under a section head with that mod's name. When no other mod owns the tab,
-- a source's support file may register the tab itself and draw its rows alone.
--
-- This file only keeps the list and answers the owner's questions; it draws nothing and
-- adds no tab. It is loaded with every game (it is harmless with no source added).
--
-- A source (def) gives:
--   owns(id)                                  true when a row id is one of its rows
--   counts(win, q, only)                      its rows: all, with a trait now, shown under Find / the switch
--   layout(win, L, x, y, w, q, only, hosted)  adds its items to L.items (kind "ext"); returns the new y
--   drawItem(panel, win, it, dy, mx, my, sel) draws one of its items; returns the hovered row's id or nil
--   drawDetail(panel, win, id, x, y, w, h, sc) draws the details at the foot for one of its rows
--   click(win, it)                            a click on one of its items; returns a row id to pick, or nil
--   focusable(win, it, dy)                    the controller's stop for one of its items, or nil
-- ============================================================================

ZeD = ZeD or {}
-- (keep a table another file made first: either file may load before the other)
ZeD.TraitsTab = ZeD.TraitsTab or { sources = {} }
local TT = ZeD.TraitsTab

-- add (or replace) a source; the order of adding is the order on the tab
function TT.addSource(id, def)
    def.id = id
    for i, s in ipairs(TT.sources) do
        if s.id == id then TT.sources[i] = def; return end
    end
    TT.sources[#TT.sources + 1] = def
end

-- every source, in order
function TT.list() return TT.sources end

-- the one source that owns a row id (or nil)
function TT.ownerOf(id)
    if id == nil then return nil end
    for _, s in ipairs(TT.sources) do
        -- pcall: a source's error must never break the tab that hosts it
        local ok, yes = pcall(s.owns, id)
        if ok and yes then return s end
    end
    return nil
end

-- every source's rows added up: all of them, those with a trait now, those shown
function TT.counts(win, q, only)
    local all, with, shown = 0, 0, 0
    for _, s in ipairs(TT.sources) do
        local ok, a, b, c = pcall(s.counts, win, q, only)
        if ok then all, with, shown = all + (a or 0), with + (b or 0), shown + (c or 0) end
    end
    return all, with, shown
end

-- every source lays out its items after the host's own (hosted = true: under its mod's name)
function TT.layout(win, L, x, y, w, q, only)
    for _, s in ipairs(TT.sources) do
        local ok, ny = pcall(s.layout, win, L, x, y, w, q, only, true)
        if ok and type(ny) == "number" then y = ny
        elseif not ok and ZeD.logOnce then ZeD.logOnce("traits tab layout " .. tostring(s.id), ny) end
    end
    return y
end

-- an item a source added (it.src is that source)
function TT.drawItem(panel, win, it, dy, mx, my, sel)
    local ok, hid = pcall(it.src.drawItem, panel, win, it, dy, mx, my, sel)
    if not ok then
        if ZeD.logOnce then ZeD.logOnce("traits tab draw " .. tostring(it.src.id), hid) end
        return nil
    end
    return hid
end

-- the details at the foot for a source's row; false when no source owns the id
function TT.drawDetail(panel, win, id, x, y, w, h, sc)
    local s = TT.ownerOf(id)
    if not s then return false end
    local ok, err = pcall(s.drawDetail, panel, win, id, x, y, w, h, sc)
    if not ok and ZeD.logOnce then ZeD.logOnce("traits tab detail " .. tostring(s.id), err) end
    return true
end

-- a click on a source's item; returns the row id to pick (or nil)
function TT.click(win, it)
    local ok, id = pcall(it.src.click, win, it)
    return ok and id or nil
end

-- the controller's stop for a source's item (or nil)
function TT.focusable(win, it, dy)
    local ok, el = pcall(it.src.focusable, win, it, dy)
    return ok and el or nil
end
