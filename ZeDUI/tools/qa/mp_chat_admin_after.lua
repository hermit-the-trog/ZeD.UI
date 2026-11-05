-- ZeDUI/tools/qa/mp_chat_admin_after.lua  (Nov 5 2026, QA): after a rejoin, did god mode ticked in the Admin tab stay
-- (the server's record); the chat window's place kept (Lua/ZeD_chatwin.txt); then god mode off again. grep "ZEDQA mcb".
local p = getPlayer()
print("ZEDQA mcb after the rejoin: god mode " .. tostring(p:isGodMod()))
local r = getFileReader("ZeD_chatwin.txt", false)
local l = r and r:readLine(); if r then r:close() end
print("ZEDQA mcb chat window place saved: " .. tostring(l))
pcall(function() ZeD.Chat.open(false) end)
local n = 0
local function t()
    n = n + 1
    if n == 30 then
        local w = ZeD.Chat.win
        print("ZEDQA mcb chat window reopened at " .. tostring(w and (w:getX() .. "," .. w:getY() .. " " .. w:getWidth() .. "x" .. w:getHeight())))
        if w then w:setVisible(false) end
        if p:isGodMod() then pcall(function() p:setGodMod(false); sendPlayerExtraInfo(p) end) end
        print("ZEDQA mcb DONE")
        Events.OnTick.Remove(t)
    end
end
Events.OnTick.Add(t)
