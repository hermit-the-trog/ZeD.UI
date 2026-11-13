-- ZeDUI/tools/qa/zedqa_de_names.lua  (Nov 7 2026, QA; merge 1, German leftovers): the Player card's profession and trait names come
-- from the viewer's own game by id (ZeD_AdminCards.lua P.gameNames: CharacterProfessionDefinition / CharacterTraitDefinition keyed
-- by tostring(getType())), and the server sends the ids as tostring(profession) ("base:farmer"). In the game's language: the
-- character's own profession id looked up the same way, and a few traits and skills, so a German client reads German names.
-- Also the clock and a short date as the cards print them. grep "ZEDQA den".
local function say(s) print("ZEDQA den " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
say("language " .. lang)
local function defs(class, listFn)
    local out, n = {}, 0
    local list = class and class[listFn] and class[listFn]()
    if list then
        for i = 0, list:size() - 1 do
            local d = list:get(i)
            if d and d.getType and d.getUIName then out[tostring(d:getType())] = d:getUIName(); n = n + 1 end
        end
    end
    return out, n
end
local okP, prof, np = pcall(defs, CharacterProfessionDefinition, "getProfessions")
local okT, trait, nt = pcall(defs, CharacterTraitDefinition, "getTraits")
say("professions " .. tostring(np) .. ", traits " .. tostring(nt))
do
    local ks = {}
    for k, v in pairs(trait or {}) do if #ks < 6 then ks[#ks + 1] = k .. "=" .. tostring(v) end end
    say("some trait ids as the game keys them: " .. table.concat(ks, ", "))
end
local mine
pcall(function() mine = tostring(getPlayer():getDescriptor():getCharacterProfession()) end)
say("this character's profession id (as the server sends it): " .. tostring(mine) .. " -> " .. tostring(prof and prof[mine]))
check(mine ~= nil and prof and prof[mine] ~= nil, "the server's profession id finds the game's name on this client")
local shown = {}
for _, k in ipairs({ "base:farmer", "base:parkranger", "base:fireofficer", "base:unemployed" }) do shown[#shown + 1] = k .. "=" .. tostring(prof and prof[k]) end
say("professions: " .. table.concat(shown, ", "))
shown = {}
for _, k in ipairs({ "base:strong", "base:gardener", "base:smoker", "base:outdoorsman" }) do shown[#shown + 1] = k .. "=" .. tostring(trait and trait[k]) end
say("traits: " .. table.concat(shown, ", "))
if lang == "DE" then
    check(prof and prof["base:farmer"] and prof["base:farmer"] ~= "Farmer", "a German client reads a German profession (" .. tostring(prof and prof["base:farmer"]) .. ")")
    check(trait and trait["base:strong"] and trait["base:strong"] ~= "Strong", "a German client reads a German trait (" .. tostring(trait and trait["base:strong"]) .. ")")
end
local okC, c24 = pcall(function() return getCore():getOptionClock24Hour() end)
say("the game's 24-hour clock option: " .. tostring(c24))
say(pass .. " passed, " .. fail .. " failed")
say("DONE")
