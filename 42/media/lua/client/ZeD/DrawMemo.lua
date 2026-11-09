-- ZeD-UI/42/media/lua/client/ZeD/DrawMemo.lua
-- ============================================================================
-- DRAW MEMO — client; a helper under the atoms. Writes down the draws a block
-- of a tab asks of its panel (a skill row, the thermal grid, a slot row) and
-- plays them back on later frames while nothing the block depends on has
-- changed, so the block's layout, measuring and colour picking run once
-- instead of every frame. The panel gets exactly the same calls with exactly
-- the same values, in the same order; a surface strip (ZeD.Surface.fill: its
-- draw and its claim on the window body) is asked for again on each play.
-- The one thing to know: the caller decides when the kept draws are still
-- good (its own key: the block's data, place, size, focus, the palette ZeD.T
-- and ZeD.DrawMemo.epoch()). Nothing that hangs on the pointer or the clock
-- is kept: a block's hover tests are written down (DM.hovers) for the caller
-- to ask again each frame, and its hover washes stay outside the block.
-- ============================================================================

ZeD = ZeD or {}
ZeD.DrawMemo = ZeD.DrawMemo or {}
local DM = ZeD.DrawMemo

-- The recorder: stands in for the panel while a block draws. Draw calls are
-- written down (their name, how many values, the values); anything else
-- (getMouseX, a field such as zedScaled or javaObject, a field written) is
-- the real panel's.
local recMT = {}
-- A block that draws on the panel's Java element itself (panel.javaObject:DrawSubTextureRGBA, the
-- license's pattern) gets a stand-in for it too: each call written down as "__jo:<method>", for
-- the play to make on the panel's own element.
local joMT = {}
joMT.__index = function(jr, k)
    return function(_, ...)
        local cmds = rawget(rawget(jr, "_rec"), "_cmds")
        cmds[#cmds + 1] = { "__jo:" .. k, select("#", ...), ... }
    end
end
recMT.__index = function(rec, k)
    local real = rawget(rec, "_real")
    local v = real[k]
    if k == "javaObject" and v ~= nil then
        local jr = rawget(rec, "_jo")
        if not jr then jr = setmetatable({ _rec = rec }, joMT); rawset(rec, "_jo", jr) end
        return jr
    end
    if type(v) == "function" then
        if type(k) == "string" and (string.sub(k, 1, 4) == "draw" or k == "setStencilRect" or k == "clearStencilRect") then
            return function(_, ...)
                local cmds = rawget(rec, "_cmds")
                cmds[#cmds + 1] = { k, select("#", ...), ... }
            end
        end
        return function(_, ...) return v(real, ...) end
    end
    return v
end
recMT.__newindex = function(rec, k, v) rawget(rec, "_real")[k] = v end

local function isRec(p) return type(p) == "table" and getmetatable(p) == recMT end

-- While a block records, two library calls are watched for it: a surface fill (written down
-- whole as "__fill": the play asks ZeD.Surface.fill of the panel, which draws the strip and
-- claims it, in its place among the draws) and a hover test (written down for DM.hovered).
-- Both pass straight through for any other panel. They are put in place on the first
-- recording and taken out when the last one ends.
local depth = 0
local origFill, origMouseIn = nil, nil
local function recFill(p, x, y, w, h, tokenName)
    if isRec(p) then
        local cmds = rawget(p, "_cmds")
        cmds[#cmds + 1] = { "__fill", 5, x, y, w, h, tokenName }
        return
    end
    return origFill(p, x, y, w, h, tokenName)
end
local function recMouseIn(p, x, y, w, h, view)
    if isRec(p) then
        local hv = rawget(p, "_hovers")
        hv[#hv + 1] = { x, y, w, h, view }
    end
    return origMouseIn(p, x, y, w, h, view)
end
local function watchOn()
    local S, A = ZeD.Surface, ZeD.Atoms
    if S and S.fill and S.fill ~= recFill then origFill = S.fill; S.fill = recFill end
    if A and A.mouseIn and A.mouseIn ~= recMouseIn then origMouseIn = A.mouseIn; A.mouseIn = recMouseIn end
end
local function watchOff()
    local S, A = ZeD.Surface, ZeD.Atoms
    if S and S.fill == recFill then S.fill = origFill end
    if A and A.mouseIn == recMouseIn then A.mouseIn = origMouseIn end
end

-- a kept surface fill, asked again of the panel
local function playFill(panel, x, y, w, h, tokenName)
    ZeD.Surface.fill(panel, x, y, w, h, tokenName)
end

-- what plays the written-down calls that are not the panel's own methods: the fills, and a
-- call on the panel's Java element (one caller made per method, the first time it is played)
local special = { __fill = playFill }
local function specialFor(name)
    local f = special[name]
    if f == nil and string.sub(name, 1, 5) == "__jo:" then
        local m = string.sub(name, 6)
        f = function(panel, ...)
            local jo = panel.javaObject
            if jo ~= nil then return jo[m](jo, ...) end
        end
        special[name] = f
    end
    return f
end

--- A recorder for panel: draw the block into it, then DM.finish plays the block on the panel
--- and returns what it kept. Recorders nest (each its own).
function DM.begin(panel)
    if depth == 0 then watchOn() end
    depth = depth + 1
    return setmetatable({ _real = panel, _cmds = {}, _hovers = {} }, recMT)
end

--- Plays kept draws on panel, each with the values it was asked with.
function DM.play(panel, cmds)
    for i = 1, #cmds do
        local c = cmds[i]
        local f = panel[c[1]]
        if f == nil then f = specialFor(c[1]) end
        local n = c[2]
        -- (as many values as the block passed: a draw that tests for a missing colour still sees one missing)
        if n == 8 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10])
        elseif n == 9 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11])
        elseif n == 7 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9])
        elseif n == 6 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8])
        elseif n == 5 then f(panel, c[3], c[4], c[5], c[6], c[7])
        elseif n == 4 then f(panel, c[3], c[4], c[5], c[6])
        elseif n == 3 then f(panel, c[3], c[4], c[5])
        elseif n == 2 then f(panel, c[3], c[4])
        elseif n == 1 then f(panel, c[3])
        elseif n == 0 then f(panel)
        elseif n == 10 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
        elseif n == 12 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12], c[13], c[14])
        elseif n == 13 then f(panel, c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15])
        else f(panel, unpack(c, 3, n + 2)) end
    end
end

--- Ends a recording: plays the block on the real panel (this frame draws it as it always did)
--- and returns the kept draws for DM.play, and the block's hover tests (DM.hovers).
function DM.finish(rec)
    depth = depth - 1
    if depth <= 0 then depth = 0; watchOff() end
    local cmds = rawget(rec, "_cmds")
    DM.play(rawget(rec, "_real"), cmds)
    return cmds, rawget(rec, "_hovers")
end

--- The hover tests a recorded block made (ZeD.Atoms.mouseIn), in order, asked again of panel:
--- true for the i-th when the pointer is on it this frame.
function DM.hovered(panel, hovers, i)
    local h = hovers and hovers[i]
    if not h then return false end
    return ZeD.Atoms.mouseIn(panel, h[1], h[2], h[3], h[4], h[5])
end

-- The palette a block's colours come from. ZeD.T is rebuilt on a theme, accent, text size or scale
-- change, but a window with its own accent swaps colours into it for its own drawing (accent,
-- hover, text, borders, surfaces: ZeD_Window._drawFrame), and its see-through puts the surfaces
-- in tables of its own whose alpha moves while it fades to solid in use (_swapSurfaces). So the
-- state is told by the swapped colours' tables and the surfaces' values, not ZeD.T alone.
local SIG_REFS = { "accent", "accentBright", "hover", "text", "textHead", "textDim", "toneHi", "toneLo",
    "textOnFocus", "border", "borderS" }
local SIG_SURF = { "base", "surf1", "surf2", "surf3", "surf4" }
local snap = {}                      -- the last state seen, field by field
local stateId, stateNext = nil, 0    -- its number; numbers are never given twice to different states
local stateIds, stateN = {}, 0       -- a state seen before keeps its number (past 256 kept, new numbers)
local refIds, refN = {}, 0           -- a colour table's number, for the state's words
local function refId(t)
    if t == nil then return 0 end
    local id = refIds[t]
    if not id then
        if refN >= 512 then refIds, refN = {}, 0 end
        refN = refN + 1
        stateNext = stateNext + 1
        id = stateNext
        refIds[t] = id
    end
    return id
end
local function sameState(T, e, test)
    if snap.T ~= T or snap.e ~= e or snap.test ~= test then return false end
    for i = 1, #SIG_REFS do
        if snap[i] ~= T[SIG_REFS[i]] then return false end
    end
    local j = #SIG_REFS
    for i = 1, #SIG_SURF do
        local c = T[SIG_SURF[i]]
        if snap[j + 1] ~= c then return false end
        if c and (snap[j + 2] ~= c.r or snap[j + 3] ~= c.g or snap[j + 4] ~= c.b or snap[j + 5] ~= c.a) then return false end
        j = j + 5
    end
    return true
end
local function newState(T, e, test)
    snap.T, snap.e, snap.test = T, e, test
    local words = { refId(T), e, test and 1 or 0 }
    for i = 1, #SIG_REFS do
        local v = T[SIG_REFS[i]]
        snap[i] = v
        words[#words + 1] = refId(v)
    end
    local j = #SIG_REFS
    for i = 1, #SIG_SURF do
        local c = T[SIG_SURF[i]]
        snap[j + 1] = c
        words[#words + 1] = refId(c)
        if c then
            snap[j + 2], snap[j + 3], snap[j + 4], snap[j + 5] = c.r, c.g, c.b, c.a
            words[#words + 1] = string.format("%.6f %.6f %.6f %.6f", c.r or 0, c.g or 0, c.b or 0, c.a or 1)
        end
        j = j + 5
    end
    local sig = table.concat(words, "|")
    local id = stateIds[sig]
    if not id then
        if stateN >= 256 then stateIds, stateN = {}, 0 end
        stateNext = stateNext + 1
        id = stateNext
        stateIds[sig] = id
        stateN = stateN + 1
    end
    stateId = id
    return id
end

--- What the kept draws also hang on beyond the caller's key: a number for the state they were
--- drawn in: the measures (fonts, root scale, language, text size: ZeD.Text.measureEpoch), the
--- test language (ZeD.tr's stretched words) and the palette as this window draws it (above).
--- nil while the fonts are still loading, when nothing should be kept.
function DM.epoch()
    local X = ZeD.Text
    local e = X and X.measureEpoch and X.measureEpoch() or nil
    if e == nil then return nil end
    local st = ZeD._trState
    local test = (st and st.on) and true or false
    local T = ZeD.T
    if stateId and sameState(T, e, test) then return stateId end
    return newState(T, e, test)
end
