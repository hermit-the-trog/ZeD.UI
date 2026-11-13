-- ZeDUI/tools/qa/zedqa_navmap.lua  (Oct 19 2026)
-- The controller nav audit (director: "audit cone navigation for controller
-- when various events/actions are triggered ... the map tab was particularly
-- unfriendly"). For every tab of both windows, and for every focusable
-- element in the window's ring, asks the focus manager where each D-pad
-- direction would go (Focus.previewMove: a dry run, focus never moves) and
-- reports per tab:
--   * TRAP     an element with its own D-pad handler that the D-pad cannot leave: the element does not say its
--              handler hands back the moves it does not hold (dpadExits), or the dry run finds no other stop in any
--              direction. A handler that takes a press and passes the rest on (Skills rows, the doll's slots) is no trap.
--   * ISLAND   an element no other element's move reaches
--   * STUCK    an element with no move at all in some direction (fine at
--              an edge; listed for review)
--   * the full map of moves for the tabs named in DUMP
-- grep "ZEDQA nav". Restores each window's focus afterwards.
-- Nov 12 2026 (test cleanup, SHRINK; plan amendment 7): a trap or an island counts now. The first run under the new
-- rule makes a LIST for triage, not failing lines: STRICT is false, each one prints as "LIST trap ..." or
-- "LIST island ..." and the totals close the run. Once that list is triaged (each entry fixed in the mod or named
-- in KNOWN below), set STRICT = true: from then on every trap or island not in KNOWN is a failing line. The full
-- move dumps (the long part of every report) are off; name a tab in DUMP to get its map back.
-- A tab with no controls at all is a failing line in both modes (the tab did not draw).
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local STRICT = true   -- (Nov 12 2026: the first list was triaged: 7 islands were one real bug, fixed; 87 traps were misreads)
local KNOWN = {}   -- e.g. ["world maps trap mapcanvas"] = true: accepted after triage, never counted
local DUMP = {}
local nTrap, nIsland, nTabs = 0, 0, 0
local function say(s) print("ZEDQA nav " .. tostring(s)) end
local function found(kind, label, tabId, id)
    local key = label .. " " .. tabId .. " " .. kind .. " " .. id
    if KNOWN[key] then return end
    if kind == "trap" then nTrap = nTrap + 1 else nIsland = nIsland + 1 end
    say((STRICT and "FAIL " or "LIST ") .. kind .. ": " .. key)
end
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(getPlayer():getPlayerNum()) end
cw = ZeD_CharacterWindow.getWindow(); ww = ZeD_WorldWindow.getWindow()
Det.setLockedMode(Det.MODE_GAMEPAD)
local function tabsOf(strip) local out = {}; for _, z in ipairs(strip._hitZones or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = { id = z.id:sub(5), x = z.x + 2, y = z.y + 2 } end end; return out end
local DIRS = { "up", "down", "left", "right" }
local SHORT = { up = "U", down = "D", left = "L", right = "R" }

local function audit(label, w, tabId)
    local savedIdx = w._focusIdx
    local savedEl = {}
    for zi, z in ipairs(w._focusRing or {}) do savedEl[zi] = z.focusedElementIdx end
    local all, incoming = {}, {}
    for zi, z in ipairs(w._focusRing or {}) do
        if z.focusable and z.elements then
            for ei, e in ipairs(z.elements) do
                all[#all + 1] = { zi = zi, ei = ei, zone = z.zone, id = tostring(e.id), custom = e.onDpadDir ~= nil, exits = e.dpadExits == true }
            end
        end
    end
    local lines, traps, stuck = {}, {}, {}
    for _, a in ipairs(all) do
        w._navLast = nil   -- (no way-back from an earlier move)
        w._focusIdx = a.zi
        w._focusRing[a.zi].focusedElementIdx = a.ei
        local parts, none = {}, {}
        local realExit = false
        for _, d in ipairs(DIRS) do
            local r = Focus.previewMove(w, d)
            if r.zone then
                local key = r.zone .. "|" .. tostring(r.id)
                if key ~= a.zone .. "|" .. a.id then incoming[key] = true; realExit = true end
                if r.dpadExits == true then a.exits = true end
                parts[#parts + 1] = SHORT[d] .. ">" .. ((r.zone == a.zone) and "" or (r.zone .. ":")) .. tostring(r.id) .. (r.pass == "half" and "~" or "")
            else
                parts[#parts + 1] = SHORT[d] .. ">-"
                none[#none + 1] = SHORT[d]
            end
        end
        if a.custom and not (a.exits and realExit) then traps[#traps + 1] = a.id end
        if #none > 0 then stuck[#stuck + 1] = a.id .. "(" .. table.concat(none) .. ")" end
        lines[#lines + 1] = a.zone .. ":" .. a.id .. (a.custom and " [OWN D-PAD]" or "") .. "  " .. table.concat(parts, " ")
    end
    local islands = {}
    for _, a in ipairs(all) do if not incoming[a.zone .. "|" .. a.id] then islands[#islands + 1] = a.zone .. ":" .. a.id end end
    say(label .. " " .. tabId .. ": " .. #all .. " targets | TRAP " .. #traps .. " {" .. table.concat(traps, ",") .. "} | ISLAND " .. #islands .. " {" .. table.concat(islands, ",") .. "}")
    say(label .. " " .. tabId .. " STUCK: " .. table.concat(stuck, " "))
    nTabs = nTabs + 1
    for _, id in ipairs(traps) do found("trap", label, tabId, id) end
    for _, id in ipairs(islands) do found("island", label, tabId, id) end
    -- (Loot always has rows and buttons; another tab may be empty by design, so only Loot is held to it)
    if #all == 0 and tabId == "loot" then say("FAIL " .. label .. " " .. tabId .. ": no controls at all (the tab did not draw)") end
    if DUMP[tabId] then for _, l in ipairs(lines) do say("  " .. label .. " " .. tabId .. " " .. l) end end
    w._focusIdx = savedIdx
    for zi, z in ipairs(w._focusRing or {}) do z.focusedElementIdx = savedEl[zi] end
end

local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local n0 = 30
local function walk(label, win, strip)
    for _, t in ipairs(tabsOf(strip)) do
        at(n0, function() strip:onMouseDown(t.x, t.y); Focus.claimFocus(win) end)
        at(n0 + 45, function() local ok, e = pcall(audit, label, win, t.id); if not ok then say("ERR " .. t.id .. " " .. tostring(e)) end end)
        n0 = n0 + 55
    end
    at(n0, function() for _, t in ipairs(tabsOf(strip)) do if t.id == "loot" then strip:onMouseDown(t.x, t.y) end end end); n0 = n0 + 20
end
-- (the strips have their tab zones once the windows have drawn)
at(15, function()
    walk("char", cw, cw._tabStripPanel)
    walk("world", ww, ww._actionTabStrip)
    at(n0, function()
        Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
        if nTabs == 0 then say("FAIL no tab was audited") end
        say(string.format("%d tabs audited: %d traps, %d islands (%s)", nTabs, nTrap, nIsland,
            STRICT and "strict: each one is a failing line" or "first run under the new rule: a list for triage, not counted against the run"))
        say("DONE")
    end)
end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then say("step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick)
say("start")
