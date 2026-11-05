-- ZeDUI/tools/qa/mp_newchar.lua  (Nov 5 2026, QA; multiplayer): a new account on the test server goes through the
-- spawn region, profession and character screens. Presses Next on whichever is showing, a few times over, as the
-- game's own buttons do, then the world loads. Runs at the main menu (the bridge's front-end). grep "ZEDQA mpn".
local function say(s) print("ZEDQA mpn " .. tostring(s)) end
local MS = MainScreen and MainScreen.instance
local n, pressed = 0, 0
local function vis(w) return w and w.isVisible and w:isVisible() end
local function tick()
    n = n + 1
    if n % 60 ~= 0 then return end
    local ok, e = pcall(function()
        local sp = MapSpawnSelect and MapSpawnSelect.instance
        if vis(sp) then say("spawn region: Next"); sp:onOptionMouseDown({ internal = "NEXT" }, 0, 0); pressed = pressed + 1; return end
        local prof = MS and MS.charCreationProfession
        if vis(prof) then say("profession: Next"); prof:onOptionMouseDown({ internal = "NEXT" }, 0, 0); pressed = pressed + 1; return end
        local main = MS and MS.charCreationMain
        if vis(main) then
            pcall(function() main.forenameEntry:setText("Benny"); main.surnameEntry:setText("Marks") end)
            say("character: Next (the world loads)"); main:onOptionMouseDown({ internal = "NEXT" }, 0, 0); pressed = pressed + 1
            Events.OnFETick.Remove(tick); say("DONE"); return
        end
    end)
    if not ok then say("ERR " .. tostring(e)) end
    if n > 60 * 40 then Events.OnFETick.Remove(tick); say("nothing to press after 40 tries (" .. pressed .. " pressed)"); say("DONE") end
end
Events.OnFETick.Add(tick)
say("start")
