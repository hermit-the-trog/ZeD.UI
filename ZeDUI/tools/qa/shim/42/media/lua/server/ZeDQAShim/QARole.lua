-- ZeDQAShim/42/media/lua/server/ZeDQAShim/QARole.lua   DEV ONLY, never stage, never upload.
-- ============================================================================
-- What lets QA test the server's own permission checks (ZeDUI/MP_SERVER_PART_DESIGN.md, Part D). A -debug client may
-- only join as an admin, and the server refuses /setaccesslevel on the logged-in account, so the test client asks here:
--   ZeDQA.role {name}    runs setRole on the sender's server object, the role the server part reads. The connection's
--                        role stays, so the -debug client stays on. "ZeDQA role" comes back with the role's name.
--   ZeDQA.nolimits       clears the sender's rate limits, so a run can file six tickets without waiting five minutes
-- The file lives in the repo at ZeDUI/tools/qa/shim/...; mp_server.ps1 -Start copies it into the shim on both sides, or
-- the Lua checksum refuses the join. It is in the shim and not in ZeD: no player's server ever has this.
-- ============================================================================
if not isServer() then return; end;

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "ZeDQA" or not player then return end
    if command == "nolimits" then
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
    end
end)
