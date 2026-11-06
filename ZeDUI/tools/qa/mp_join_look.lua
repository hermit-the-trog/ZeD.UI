-- ZeDUI/tools/qa/mp_join_look.lua  (Nov 6 2026, QA): what is on screen when a join stops short of the game: every visible UI element, printed. The join's wait runs it.
local function say(s) print("ZEDQA mjl " .. tostring(s)) end
local n = 0
local function look()
    n = n + 1
    if n % 300 ~= 1 then return end
    local out = {}
    local u = UIManager.getUI()
    for k = 0, u:size() - 1 do
        local e = u:get(k)
        local t = e:getTable()
        local name = t and t.Type or (e.getClass and e:getClass():getSimpleName())
        out[#out + 1] = tostring(name)
    end
    say("visible " .. table.concat(out, " "))
    local MS = MainScreen and MainScreen.instance
    if MS then
        for _, f in ipairs({ "charCreationProfession", "charCreationMain", "mapSpawnSelect", "connectToServer", "serverConnectPopup", "worldSelect" }) do
            local w = MS[f]
            if w then say(f .. " visible " .. tostring(w:isVisible())) end
        end
    end
    say("MapSpawnSelect " .. tostring(MapSpawnSelect and MapSpawnSelect.instance and MapSpawnSelect.instance:isVisible()))
    say("ConnectToServer " .. tostring(ConnectToServer and ConnectToServer.instance and ConnectToServer.instance:isVisible()))
    if ConnectToServer and ConnectToServer.instance and ConnectToServer.instance.connectLabel then say("connect words: " .. tostring(ConnectToServer.instance.connectLabel:getName())) end
    if n > 3600 then Events.OnFETick.Remove(look); Events.OnTick.Remove(look); say("DONE") end
end
Events.OnFETick.Add(look)
pcall(function() getCore():TakeFullScreenshot("mjl_join.png") end)
