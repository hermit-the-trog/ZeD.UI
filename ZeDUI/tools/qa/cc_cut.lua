-- ZeDUI/tools/qa/cc_cut.lua  (Nov 7 2026, Build): the sims' way to run real pieces of CraftingCore.lua without
-- loading the whole module (it requires the drawing library). Each opening text names one top-level function or
-- local function; it is cut from there to its first unindented "end", and the pieces run together on the caller's
-- CC table, with the module's own locals they use (_phaseN, LOGIC_EVERY_MS, LOGIC_FULL_MS, STATUS_RANK) read from the
-- file.
--   local cut = dofile(ROOT .. "ZeDUI/tools/qa/cc_cut.lua")
--   cut(ROOT, CC, { "function CC.due(", "function CC.refreshRow(" })
return function(ROOT, CC, openings)
    local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/CraftingCore.lua", "rb"))
    local src = (f:read("*a"):gsub("\r\n", "\n"))
    f:close()
    local parts = { "local CC = ...\n" }
    for _, pat in ipairs({ "\nlocal _phaseN = [^\n]*", "\nlocal LOGIC_EVERY_MS = [^\n]*", "\nlocal LOGIC_FULL_MS *= [^\n]*",
                           "\nlocal STATUS_RANK = [^\n]*" }) do
        local line = src:match(pat)
        if line then parts[#parts + 1] = line .. "\n" end
    end
    for _, open in ipairs(openings) do
        local a = src:find(open, 1, true)
        assert(a, "cc_cut: not found in CraftingCore.lua: " .. open)
        local e = src:find("\nend\n", a, true)
        assert(e, "cc_cut: no end for " .. open)
        parts[#parts + 1] = src:sub(a, e + 4)
    end
    local chunk = assert(loadstring(table.concat(parts), "=CraftingCore.lua (cut)"))
    chunk(CC)
    return CC
end
