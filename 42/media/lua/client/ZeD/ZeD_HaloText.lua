-- ZeD-UI/42/media/lua/client/ZeD/ZeD_HaloText.lua
-- ============================================================================
-- THE GAME'S OVERHEAD NOTES. Client-side override. The red and green lines the game puts over your head ("Too
-- heavy", "Can't reach") were nearly unreadable, so ZeD catches them into the same bubble plus a running log, and a
-- note you missed can be read later. ZeD setup's Overhead notes switch (Settings.lua: haloBubble) turns it on.
--
-- The game's HaloTextHelper is a Java class whose functions Lua sees as a table; every one of the game's Lua callers
-- (about 50: "Not safe to sleep", "Too heavy", the mechanics and building notes) and ZeD's own call through that
-- global, so wrapping its functions catches them all. A caught line goes to
-- ZeD's bubble over the head (ZeD_Bubbles: B.note, the status mark from its colour) and to the Messages window's
-- log (ZeD_Messages: M.halo) instead of the game's own text. With the switch off, in safe mode, or for a character
-- that is not a local player, the line goes to the game as before.
--
-- What Lua cannot catch: the game's Java code calls HaloTextHelper itself for skill XP ("+5 Carpentry"), a level
-- gained or lost, a recipe learned on its own, a scratch ticket win, a card drawn, dice rolled, and multiplayer notes
-- from the server (the Java callers: IsoGameCharacter$XP.AddXP, IsoGameCharacter level up and down, CraftRecipe,
-- Item.researchRecipes, RecipeCodeHelper, RecipeCodeOnCreate, HaloTextPacket). Those still draw as the game draws
-- them. XP and levels are logged from the game's own events (AddXP, LevelPerk) so they can be read later too, but not
-- put in the bubble, so nothing shows twice.
-- ============================================================================

ZeD = ZeD or {}
ZeD.HaloText = ZeD.HaloText or {}
local H = ZeD.HaloText

local function on()
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    local S = ZeD.Settings
    return S and S.haloBubbleOn and S.haloBubbleOn() or false
end

-- the player number of a local player (nil: another player, or not a player)
local function localNum(p)
    if not p then return nil end
    local ok, isLocal = pcall(function() return p:isLocalPlayer() end)
    if not (ok and isLocal) then return nil end
    local ok2, pn = pcall(function() return p:getPlayerNum() end)
    return ok2 and pn or nil
end

-- the tone of a colour the game passed: a ColorRGB (r, g, b as 0-255) or three numbers
local function toneOf(c, g, b)
    local r
    if type(c) == "number" then r = c
    elseif c ~= nil then
        local ok = pcall(function() r, g, b = c.r, c.g, c.b end)
        if not ok then return nil end
    end
    if not (r and g and b) then return nil end
    if g > r + 40 and g > b then return "good" end
    if r > g + 40 and r > b then return "bad" end
    return nil
end

-- a caught line: the bubble and the log; true when ZeD took it
local function take(p, text, tone)
    if not on() then return false end
    local pn = localNum(p)
    if pn == nil then return false end
    text = tostring(text or "")
    if text == "" then return true end
    -- (the game separates joined notes with [br/] and may carry its colour markup: one note a part)
    for part in (text:gsub("%[br/%]", "\n") .. "\n"):gmatch("(.-)\n") do
        -- (Kahlua may hand an empty capture over as nil)
        local t = tostring(part or ""):gsub("%[[^%]]*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if t ~= "" then
            if ZeD.Bubbles and ZeD.Bubbles.note then pcall(ZeD.Bubbles.note, pn, t, tone) end
            if ZeD.Messages and ZeD.Messages.halo then pcall(ZeD.Messages.halo, t, tone) end
        end
    end
    return true
end
H.take = take

-- the wrappers, put on once; the game's own kept in H.orig
function H.install()
    local HT = HaloTextHelper
    if H.installed or type(HT) ~= "table" then return end
    H.orig = H.orig or {}
    local O = H.orig
    O.addText, O.addGoodText, O.addBadText, O.addTextWithArrow = HT.addText, HT.addGoodText, HT.addBadText, HT.addTextWithArrow
    local ok = pcall(function()
        -- (each passes on exactly the arguments it was given, never padded with nils: the game picks its Java overload
        -- by the count, and a nil in an int slot throws)
        -- addText(player, text [, separator] [, colour | r, g, b])
        HT.addText = function(...)
            local p, text, sep, c, g, b = ...
            local tone = nil
            if type(sep) ~= "string" then tone = toneOf(sep, c, g) else tone = toneOf(c, g, b) end
            if take(p, text, tone) then return end
            return O.addText(...)
        end
        HT.addGoodText = function(...)
            local p, text = ...
            if take(p, text, "good") then return end
            return O.addGoodText(...)
        end
        HT.addBadText = function(...)
            local p, text = ...
            if take(p, text, "bad") then return end
            return O.addBadText(...)
        end
        -- addTextWithArrow(player, text [, separator], up, colour [, arrow colour] | r, g, b [, r, g, b])
        HT.addTextWithArrow = function(...)
            local p, text, a3, a4, a5, a6, a7 = ...
            local tone
            if type(a3) == "string" then tone = toneOf(a5, a6, a7) else tone = toneOf(a4, a5, a6) end
            if take(p, text, tone) then return end
            return O.addTextWithArrow(...)
        end
    end)
    H.installed = ok
    print("[ZeD] HaloText: the game's overhead notes " .. (ok and "go to ZeD's bubble while it is on" or "could not be caught"))
end

-- XP and levels: logged only (the game draws its own line over the head for these)
local function perkName(perk)
    local ok, n = pcall(function() return perk:getName() end)
    if ok and n then return tostring(n) end
    return tostring(perk)
end
function H.onAddXP(chr, perk, amount)
    if not on() or localNum(chr) == nil or not amount or amount <= 0 then return end
    if not (ZeD.Messages and ZeD.Messages.halo) then return end
    local label = perkName(perk)
    pcall(ZeD.Messages.halo, ZeD.tr("UI_ZeD_Halo_XP", label, string.format("%.1f", amount)), "good",
        { key = "xp:" .. tostring(perk), label = label, amount = amount })
end
function H.onLevelPerk(chr, perk, level, increased)
    if not on() or localNum(chr) == nil then return end
    if not (ZeD.Messages and ZeD.Messages.halo) then return end
    local up = increased ~= false
    pcall(ZeD.Messages.halo, ZeD.tr(up and "UI_ZeD_Halo_LevelUp" or "UI_ZeD_Halo_LevelDown", perkName(perk), tostring(level or "")),
        up and "good" or "bad")
end

if Events and not H._hooked then
    H._hooked = true
    if Events.OnGameStart then Events.OnGameStart.Add(H.install) end
    if Events.OnGameBoot then Events.OnGameBoot.Add(H.install) end
    if Events.AddXP then Events.AddXP.Add(H.onAddXP) end
    if Events.LevelPerk then Events.LevelPerk.Add(H.onLevelPerk) end
end

return H
