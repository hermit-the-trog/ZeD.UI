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
        -- (Nov 6 2026: ZeD's own screens stand in for these while ZeD is on: map, traits, looks)
        local MM = ZeD and ZeD.MainMenu
        if MM and MM.root then
            for _, rv in ipairs(MM.views or {}) do
                if rv.view == MM.view and (rv.view == "spawn" or rv.view == "traits" or rv.view == "looks") then
                    local w = MM.root[rv.field]
                    say("ZeD's " .. tostring(rv.view) .. ": Next")
                    pressed = pressed + 1
                    -- (Nov 6 2026) the list sorts by language, and Next waits while the points are short: in German the first
                    -- occupation may be one that costs. The one with the most points to spare, then Next.
                    local pr = MainScreen and MainScreen.instance and MainScreen.instance.charCreationProfession
                    if rv.view == "traits" and pr and pr:PointToSpend() < 0 then
                        local best, bestI, bestC = nil, nil, -999
                        for k, it in ipairs(pr.listboxProf.items) do
                            local okc, c = pcall(function() return it.item:getCost() end)
                            if okc and c and c > bestC then best, bestI, bestC = it.item, k, c end
                        end
                        say("points short " .. tostring(pr:PointToSpend()) .. ", occupation " .. tostring(bestI) .. " of cost " .. tostring(bestC))
                        if best then pr.listboxProf.selected = bestI; pr:onSelectProf(best) end
                    end
                    if w and w.play then w:play() elseif w and w.next then w:next() end
                    if rv.view == "looks" then Events.OnFETick.Remove(tick); say("DONE") end
                    return
                end
            end
        end
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
