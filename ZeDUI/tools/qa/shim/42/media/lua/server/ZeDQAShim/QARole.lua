-- ZeDQAShim/42/media/lua/server/ZeDQAShim/QARole.lua   DEV ONLY, never stage, never upload.
-- ============================================================================
-- What lets QA test the server's own permission checks (docs/specs/MP_SERVER_PART_DESIGN.md, Part D). A -debug client may
-- only join as an admin, and the server refuses /setaccesslevel on the logged-in account, so the test client asks here:
--   ZeDQA.role {name}    runs setRole on the sender's server object, the role the server part reads. The connection's
--                        role stays, so the -debug client stays on. "ZeDQA role" comes back with the role's name.
--   ZeDQA.nolimits       clears the sender's rate limits, so a run can file six tickets without waiting five minutes
-- The file lives in the repo at ZeDUI/tools/qa/shim/...; mp_server.ps1 -Start copies it into the shim on both sides, or
-- the Lua checksum refuses the join. It is in the shim and not in ZeD: no player's server ever has this.
-- ============================================================================
if not isServer() then return; end;

-- (Nov 6 2026, QA: E8) a line every 20 s from OnTickEvenPaused, so the server's log shows it fires with nobody on
local tickSeen, tickN = 0, 0
if Events.OnTickEvenPaused then
    Events.OnTickEvenPaused.Add(function()
        tickN = tickN + 1
        local t = getTimestamp()
        if t - tickSeen >= 20 then
            tickSeen = t
            print("[ZeDQA] paused tick " .. tickN .. ", players " .. tostring(getOnlinePlayers():size()))
        end
    end)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "ZeDQA" or not player then return end
    if command == "god" then
        -- (Nov 6 2026, QA) the /godmod command stopped taking on 42.22.2 and test characters died: set on the server object
        pcall(function() player:setGodMod(true) end)
        print("[ZeDQA] god mode for " .. tostring(player:getUsername()) .. ": " .. tostring(player:isGodMod()))
    elseif command == "shortban" then
        -- (Nov 6 2026, QA: E8) the 1 hour length made short on this server, so a timed ban runs out inside a test
        if ZeD and ZeD.Adm and ZeD.Adm.LENGTH then ZeD.Adm.LENGTH.h1.sec = tonumber(args and args.sec) or 45 end
        print("[ZeDQA] h1 is now " .. tostring(ZeD and ZeD.Adm and ZeD.Adm.LENGTH.h1.sec) .. " s")
    elseif command == "nolimits" then
        if ZeD and ZeD.Srv and ZeD.Srv.mem then ZeD.Srv.mem[player:getUsername()] = nil end
        sendServerCommand(player, "ZeDQA", "nolimits", { ok = true })
    elseif command == "role" then
        local want = args and args.name
        local roles = getRoles()
        for i = 0, roles:size() - 1 do
            local r = roles:get(i)
            if r:getName() == want then
                player:setRole(r)
                print("[ZeDQA] role of " .. tostring(player:getUsername()) .. " now " .. tostring(want))
                sendServerCommand(player, "ZeDQA", "role", { name = want })
                return
            end
        end
        print("[ZeDQA] no role named " .. tostring(want))
        sendServerCommand(player, "ZeDQA", "role", { name = "none" })
    elseif command == "carspawn" then
        -- (Nov 7 2026, QA) a car {script} facing north on the square {x, y, z}, made by the server, so it runs up the drag
        -- strip (/addvehicle gives no heading)
        local sq = getCell():getGridSquare(tonumber(args.x) or 0, tonumber(args.y) or 0, tonumber(args.z) or 0)
        local v = nil
        if sq then pcall(function() v = addVehicleDebug(args.script or "Base.CarNormal", IsoDirections.N, nil, sq) end) end
        print("[ZeDQA] carspawn at " .. tostring(args.x) .. "," .. tostring(args.y) .. ": " .. tostring(v and v:getId()))
        sendServerCommand(player, "ZeDQA", "carspawn", { ok = v ~= nil, veh = v and v:getId(), sq = sq ~= nil })
    elseif command == "carprep" then
        -- (Nov 7 2026, QA: the dash with two players) the car {veh} made ready on the server: repaired, a full tank, a full
        -- battery, hotwired so ISStartVehicleEngine starts it with no key, and a key of "another mod" written into the
        -- server's copy of its mod data only (never transmitted here), to see it survive the drive
        local v = getVehicleById(tonumber(args and args.veh) or -1)
        local out = { veh = args and args.veh, ok = v ~= nil }
        if v then
            pcall(function() v:repair() end)
            for i = 0, v:getPartCount() - 1 do
                local part = v:getPartByIndex(i)
                pcall(function() v:transmitPartCondition(part) end)
                pcall(function() v:transmitPartItem(part) end)
            end
            pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()); v:transmitPartModData(g) end)
            pcall(function()
                local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
                if it then pcall(function() it:setCurrentUsesFloat(1.0) end); v:transmitPartItem(b) end
            end)
            pcall(function() v:setHotwired(true) end)
            v:getModData().QA_otherMod = "kept on the server"
            out.hot = v:isHotwired()
        end
        print("[ZeDQA] carprep " .. tostring(out.veh) .. ": " .. tostring(out.ok))
        sendServerCommand(player, "ZeDQA", "carprep", out)
    elseif command == "carread" then
        -- the server's own copy of the car's figures and the other mod's key
        local v = getVehicleById(tonumber(args and args.veh) or -1)
        local out = { veh = args and args.veh, ok = v ~= nil }
        if v then
            local md = v:getModData()
            out.odo, out.trip, out.show, out.other = md.ZeD_odo, md.ZeD_trip, md.ZeD_odoTrip, md.QA_otherMod
            out.running = v:isEngineRunning()
            local d = v:getDriver()
            out.driver = d and d:getUsername() or "none"
        end
        sendServerCommand(player, "ZeDQA", "carread", out)
    end
end)
