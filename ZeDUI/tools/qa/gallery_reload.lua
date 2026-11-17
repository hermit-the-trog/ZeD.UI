-- ZeDUI/tools/qa/gallery_reload.lua  (Nov 17 2026, QA): puts back what gallery_unload.lua took out. Every thing in
-- GAL_UNLOAD.stash still out goes back into the container it came from (the inventory, or the bag worn or held); the
-- once-a-second load log stops and the pointer is shown again. Logs the load before and after. grep "ZEDQA rel".
local function say(s) print("ZEDQA rel " .. tostring(s)) end
local U = GAL_UNLOAD
if not U then
    say("nothing to put back (gallery_unload.lua did not run in this game)")
else
    if U.watch then Events.OnPreUIDraw.Remove(U.watch) end
    U.watching = false
    say("before: " .. (U.line and U.line() or "?"))
    local n, bad = 0, 0
    for _, e in ipairs(U.stash or {}) do
        if not e.back then
            local ok = pcall(function() e.c:AddItem(e.it) end)
            if ok then n = n + 1 else bad = bad + 1; say("ERR could not put back " .. tostring(e.it:getFullType())) end
        end
    end
    U.stash = {}
    pcall(function() Mouse.setCursorVisible(U.cursorWas ~= false) end)
    say("put back " .. n .. " things" .. (bad > 0 and (", " .. bad .. " failed") or "") .. "; after: " .. (U.line and U.line() or "?"))
end
local k = 0
local function later()
    k = k + 1
    if k < 10 then return end
    Events.OnPreUIDraw.Remove(later)
    say("DONE")
end
Events.OnPreUIDraw.Add(later)
